# nginx

nginx's official unprivileged image (stable, Alpine) plus nginx's ACME module, serving one static site (mounted, not built in) over HTTPS with a certificate it obtains and renews by itself: `ghcr.io/ai-bedrock/nginx`.

**This image is public: nothing private goes in it.** The server name and the ACME directory come in at run time, never through this directory.

## Running it

It listens on 8080 (HTTP: ACME HTTP-01 challenges, everything else a 301 to `https://<SERVER_NAME>`) and 8443 (HTTPS, HTTP/2; `www.<SERVER_NAME>` gets a 301 to the apex), as uid 101; map the host's 80 and 443 to them.

- `SERVER_NAME`: the apex name the site answers to; the certificate covers it and `www.<SERVER_NAME>`
- `ACME_DIRECTORY`: the ACME server's directory URL, e.g. Let's Encrypt's `https://acme-v02.api.letsencrypt.org/directory` (its terms of service are accepted on the account's creation; no contact address, no external account binding)
- `/var/lib/nginx/acme`: the ACME account key, the certificate and its key; a volume keeps them across restarts, so a restart doesn't order a new certificate
- `/usr/share/nginx/html`: the site's files, not in this image: mount them there read-only, e.g. the website's [image](../ai-bedrock.dev/) (`--mount type=image,...`), so a site change doesn't rebuild nginx
- a read-only root works (`--read-only`) when `/etc/nginx/conf.d`, where the entrypoint renders the site, is a tmpfs the container user owns (`--tmpfs /etc/nginx/conf.d:U`); `/tmp` and `/run` are tmpfs by default

```sh
podman run -d -p 80:8080 -p 443:8443 \
  -e SERVER_NAME=example.org -e ACME_DIRECTORY=https://acme-v02.api.letsencrypt.org/directory \
  -v nginx-acme:/var/lib/nginx/acme \
  --mount type=image,source=ghcr.io/ai-bedrock/ai-bedrock.dev:stable,destination=/usr/share/nginx/html \
  ghcr.io/ai-bedrock/nginx:stable
```

## Its test

`test.sh <image> [<site image>]` runs the image as above with the website's [files](../ai-bedrock.dev/) mounted (built from that folder unless a site image is given), next to a local ACME server (pebble) on a podman network where `example.test` and `www.example.test` resolve to it, and checks: a certificate issued for both names, HTTP and www 301 to `https://example.test/`, the security headers, `robots.txt` and `sitemap.xml` 200 when the site has them, a missing path 404. CI runs it after the build and before the push; locally, `mise run test-nginx`. It is not part of the image.

## Everything it changes against upstream

- `Containerfile`: installs `nginx-module-acme` from nginx.org's Alpine repository (signed with nginx's key, which the base image carries), matching the base's nginx version; removes the default site (`conf.d/default.conf`, `index.html`, `50x.html`), leaving `/usr/share/nginx/html` empty for a mounted site; creates `/var/lib/nginx/acme` (uid 101, mode 0700); sets `NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1` so the entrypoint hands the container's resolvers to nginx; its own title and description labels; exposes 8080 and 8443
- `rootfs/etc/nginx/nginx.conf`: loads the ACME module; no version in headers; gzip for text, CSS, XML and SVG; UTF-8 charset; small request bodies; 10 s header, body and send timeouts; otherwise upstream's (temp paths in `/tmp`, logs to the container's output)
- `rootfs/etc/nginx/templates/site.conf.template`: the site, filled in from the environment by the entrypoint into `conf.d/site.conf`: the ACME issuer (directory, state path, terms accepted), the HTTP server (challenges, then 301), the HTTPS server (TLS 1.2 with forward-secret AEAD ciphers only, and 1.3; no session tickets; the certificate for the apex and www, the www redirect, HSTS for a year, a CSP for a static page without scripts, `X-Content-Type-Options`, `Referrer-Policy`, `Cross-Origin-Opener-Policy`, a `Permissions-Policy` denying camera, microphone, geolocation, payment and USB, `frame-ancestors 'none'`, a 404 page with a 404 status, cache lifetimes)
