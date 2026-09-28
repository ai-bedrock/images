# later

One line per item: `- [ ] <what> — <why it waits>`. Tick it or delete it when done.

- [ ] Keyless signing (Fulcio + Rekor through the workflow's OIDC identity) instead of the key pair, once containers/image policies match certificate URI SANs (GitHub's workflow identity; today they match emails only), so no signing secret remains
- [ ] Rebuild images built on coreos when coreos changes (a `workflow_run` trigger or a matrix) — no such image yet
- [ ] Bump nginx's base tag when nginx.org releases a new stable (by hand, or a bot that opens the change) — the daily build only follows rebuilds of the pinned tag
- [ ] An Open Graph image and structured data (JSON-LD) for the site — the placeholder carries the one line only
- [ ] A test of the nginx image in CI (a local ACME server such as pebble, then the redirects, headers and 404) — tested by hand so far
- [ ] Push trigger for more than one host (a list of targets, or an environment per host) — one host serves the site today
- [ ] Rotate the deploy key on a schedule (a new key pair, the host's `authorized_keys` and the repo secret) — no schedule yet
- [ ] Name content images after the site they serve, not a generic `site` (several sites are planned): rename the `site/` folder, its package, the quadlet and the host's image list, and delete the old package — a note from the lead, not urgent
- [ ] Sandbox `image-update@.service` and `image-update.service` (NoNewPrivileges, ProtectHome, PrivateTmp, protected kernel settings), tested with a real pull and restart — root, but its only input is a name checked against the host's list; low gain
- [ ] Turn off `gssproxy`, `fwupd` and `rpm-ostree-countme` on hosts (no NFS or Kerberos, no firmware on a VM, Fedora's usage count) — nothing of them listens on the network
- [ ] Per-address request or connection limits in nginx (`limit_req`, `limit_conn`) — a static site; a limit can hit many visitors behind one NAT address, so it needs numbers first
