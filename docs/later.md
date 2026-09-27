# later

One line per item: `- [ ] <what> — <why it waits>`. Tick it or delete it when done.

- [ ] Keyless signing (Fulcio + Rekor through the workflow's OIDC identity) instead of the key pair, once containers/image policies match certificate URI SANs (GitHub's workflow identity; today they match emails only), so no signing secret remains
- [ ] Rebuild images built on coreos when coreos changes (a `workflow_run` trigger or a matrix) — no such image yet
