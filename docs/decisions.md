# decisions

This repo's internals: what, why, what a change would cost. `by: lead` for the lead's calls, `by: ai` for the rest until the lead weighs in.

- by: lead. Images live in their own public repo, one folder per image (roles later build `FROM` coreos); nothing revealing in it.
- by: lead. Images are signed.
- by: ai. A sigstore key pair signs every pushed tag (`podman push --sign-by-sigstore-private-key`, signatures as sigstore attachments); private key and passphrase are repo secrets. Keyed, not keyless: containers/image policies match Fulcio identities by email only, and GitHub Actions certificates carry a workflow URI. Change: keyless once URIs match (later.md).
- by: ai. coreos's `policy.json` requires that signature for the whole `ghcr.io/ai-bedrock` namespace and keeps upstream's accept-anything default elsewhere, so Fedora's and third-party images pull as before. Change: narrow or widen the scope in one file.
- by: ai. CI is podman only (the containers tools CoreOS uses, from the runner): one reusable `build.yml`, one small caller per image with its path filter; a scheduled run builds only when the base's digest has no `base-<digest>` tag yet, so an unchanged image doesn't reboot hosts. Each build is pulled back through coreos's policy. Checks on `ubuntu-slim`, builds on `ubuntu-26.04` (x86_64).
- by: ai. coreos updates through bootc's own `bootc-fetch-apply-updates.timer` in a daily window (03:30 UTC plus up to 30 minutes), Zincati off: Zincati follows Fedora's update graph, not a registry tag. `bootc upgrade --apply` reboots only when a new image was staged and keeps the previous deployment for rollback.
- by: ai. coreos's host firewall is nftables in its own `inet host` table (policy drop; ICMP, DHCP replies, TCP 22, 80, 443), and nothing but sshd listens on the host itself (LLMNR and mDNS off); 80 and 443 are for a web server in a container.
