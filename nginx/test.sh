#!/usr/bin/env bash
# Tests a built nginx image end to end with podman, as it runs on a host: a local ACME server
# (pebble) issues its certificate, then the redirects, security headers, the site's files and
# the 404 are checked over the network. Usage: nginx/test.sh <image> [<site image>]; without a
# site image it builds one from site/. Exits non-zero on any failure, printing both servers' logs.
#
# The names are test names (RFC 2606's .test) that only this run's podman network resolves: the
# nginx container answers to them as network aliases, and pebble validates HTTP-01 against it.
# nginx trusts pebble's test CA through a CA bundle mounted over its system one (the ACME module
# uses the system's trust by default), so the image and its template run unchanged.
set -euo pipefail

image=${1:?usage: $0 <nginx image> [<site image>]}
site_image=${2:-}
name=example.test
pebble=ghcr.io/letsencrypt/pebble:2.10.1
here=$(cd "$(dirname "$0")" && pwd)
site=$here/../site
run=nginx-test-$$
work=$(mktemp -d)
chmod 0755 "$work" # the client runs as the image's user; nothing secret in it
failed=0

cleanup() {
  if [ $? != 0 ]; then
    echo "--- nginx log"
    podman logs "$run-nginx" 2>&1 | tail -n 60 || true
    echo "--- pebble log"
    podman logs "$run-pebble" 2>&1 | tail -n 30 || true
  fi
  podman rm -f -t 0 "$run-nginx" "$run-pebble" >/dev/null 2>&1 || true
  podman volume rm -f "$run-acme" >/dev/null 2>&1 || true
  podman network rm -f "$run" >/dev/null 2>&1 || true
  if [ "$site_image" = "localhost/$run-site" ]; then # only the one built here
    podman rmi -f "$site_image" >/dev/null 2>&1 || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

# a client on the test network: the image's own curl, trusting only pebble's CAs
client() {
  podman run --rm --network "$run" -v "$work:/w:ro,z" --entrypoint curl "$image" \
    -sS --max-time 10 --cacert /w/ca.pem "$@"
}

podman network create "$run" >/dev/null

# pebble, as "pebble" (the name its test certificate carries): HTTP-01 on nginx's HTTP port, no random validation delays or rejected nonces
cat >"$work/pebble.json" <<'EOF'
{"pebble": {
  "listenAddress": "0.0.0.0:14000",
  "managementListenAddress": "0.0.0.0:15000",
  "certificate": "test/certs/localhost/cert.pem",
  "privateKey": "test/certs/localhost/key.pem",
  "httpPort": 8080,
  "tlsPort": 8443,
  "ocspResponderURL": "",
  "externalAccountBindingRequired": false
}}
EOF
podman run -d --name "$run-pebble" --network "$run" --network-alias pebble -v "$work:/w:ro,z" \
  -e PEBBLE_VA_NOSLEEP=1 -e PEBBLE_WFE_NONCEREJECT=0 \
  "$pebble" -config /w/pebble.json >/dev/null

# pebble's test CA (it signs pebble's own HTTPS) appended to the image's system bundle
podman cp "$run-pebble:/test/certs/pebble.minica.pem" "$work/minica.pem"
podman run --rm --entrypoint cat "$image" /etc/ssl/certs/ca-certificates.crt >"$work/bundle.pem"
cat "$work/minica.pem" >>"$work/bundle.pem"

if [ -z "$site_image" ]; then
  site_image=localhost/$run-site
  podman build -q -t "$site_image" "$site" >/dev/null
fi
podman volume create "$run-acme" >/dev/null
podman run -d --name "$run-nginx" --network "$run" \
  --network-alias "$name" --network-alias "www.$name" \
  -e SERVER_NAME="$name" -e ACME_DIRECTORY="https://pebble:14000/dir" \
  -v "$run-acme:/var/lib/nginx/acme" \
  --mount "type=image,source=$site_image,destination=/usr/share/nginx/html" \
  --read-only --tmpfs /etc/nginx/conf.d:U \
  -v "$work/bundle.pem:/etc/ssl/certs/ca-certificates.crt:ro,z" \
  "$image" >/dev/null

# pebble's issuing root, then wait for the certificate
cp "$work/minica.pem" "$work/ca.pem"
for _ in $(seq 30); do
  client -f "https://pebble:15000/roots/0" >"$work/root.pem" 2>/dev/null && break
  sleep 1
done
cp "$work/root.pem" "$work/ca.pem"
issued=no
for _ in $(seq 60); do
  if client -f -o /dev/null "https://$name:8443/" 2>/dev/null; then issued=yes; break; fi
  sleep 1
done

# headers of one request, lower-cased names; status as its first line's second field
head_of() { client -o /dev/null -D - "$@" | tr -d '\r'; }
status() { awk 'NR == 1 { print $2 }' <<<"$1"; }
header() { awk -v h="$2:" 'tolower($1) == h { sub(/^[^:]*: */, ""); print; exit }' <<<"$1"; }
expect() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; failed=1; fi
}

expect "certificate issued for $name by pebble" "$issued" yes
if [ "$issued" = yes ]; then
  expect "certificate valid for www.$name" \
    "$(client -o /dev/null -w '%{ssl_verify_result}' "https://www.$name:8443/")" 0

  r=$(head_of "http://$name:8080/some/path?q=1")
  expect "http 301" "$(status "$r")" 301
  expect "http location" "$(header "$r" location)" "https://$name/some/path?q=1"

  r=$(head_of "https://www.$name:8443/some/path")
  expect "www 301" "$(status "$r")" 301
  expect "www location" "$(header "$r" location)" "https://$name/some/path"

  r=$(head_of "https://$name:8443/")
  expect "/ 200" "$(status "$r")" 200
  expect "hsts" "$(header "$r" strict-transport-security)" "max-age=31536000; includeSubDomains; preload"
  for h in content-security-policy referrer-policy cross-origin-opener-policy permissions-policy; do
    expect "$h set" "$([ -n "$(header "$r" "$h")" ] && echo yes)" yes
  done
  expect "nosniff" "$(header "$r" x-content-type-options)" nosniff
  expect "no version" "$(header "$r" server)" nginx

  for f in robots.txt sitemap.xml; do
    [ -f "$site/public/$f" ] || continue
    expect "/$f 200" "$(status "$(head_of "https://$name:8443/$f")")" 200
  done
  expect "missing path 404" "$(status "$(head_of "https://$name:8443/no-such-page")")" 404
fi

[ "$failed" = 0 ] && echo "nginx: all checks passed" || exit 1
