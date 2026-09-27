# later

One line per item: `- [ ] <what> — <why it waits>`. Tick it or delete it when done.

- [ ] Keyless signing (Fulcio + Rekor through the workflow's OIDC identity) instead of the key pair, once containers/image policies match certificate URI SANs (GitHub's workflow identity; today they match emails only), so no signing secret remains
- [ ] Rebuild images built on coreos when coreos changes (a `workflow_run` trigger or a matrix) — no such image yet
- [ ] Bump nginx's base tag when nginx.org releases a new stable (by hand, or a bot that opens the change) — the daily build only follows rebuilds of the pinned tag
- [ ] An Open Graph image and structured data (JSON-LD) for the site — the placeholder carries the one line only
- [ ] A test of the nginx image in CI (a local ACME server such as pebble, then the redirects, headers and 404) — tested by hand so far
- [ ] Push trigger for more than one host (a list of targets, or an environment per host) — one host serves the site today
- [ ] Rotate the deploy key on a schedule (a new key pair, the host's `authorized_keys` and the repo secret) — no schedule yet
