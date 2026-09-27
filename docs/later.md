# later

One line per item: `- [ ] <what> — <why it waits>`. Tick it or delete it when done.

- [ ] Keyless signing (Fulcio + Rekor through the workflow's OIDC identity) instead of the key pair, once containers/image policies match certificate URI SANs (GitHub's workflow identity; today they match emails only), so no signing secret remains
- [ ] Rebuild images built on coreos when coreos changes (a `workflow_run` trigger or a matrix) — no such image yet
- [ ] Bump nginx's base tag when nginx.org releases a new stable (by hand, or a bot that opens the change) — the daily build only follows rebuilds of the pinned tag
- [ ] An Open Graph image and structured data (JSON-LD) for the site — the placeholder carries the one line only
- [ ] A test of the nginx image in CI (a local ACME server such as pebble with an external account binding, then the redirects, headers and 404) — tested by hand so far
- [ ] nginx-acme against a CA that answers a repeated newAccount (same key, with an external account binding) with 200 and only `{"externalaccountbinding": ...}`, no `status`: the module (0.4.1) requires `status` and fails its account step on every start after the first, so no certificate is ordered or renewed. Options: a patched module (`status` optional on 200, built in a builder stage against the base's nginx source), an upstream fix, or another ACME client — needs the lead's call
