# later

One line per item: `- [ ] <what> — <why it waits>`. Tick it or delete it when done.

- [ ] Keyless signing (Fulcio + Rekor through the workflow's OIDC identity) instead of the key pair, once containers/image policies match certificate URI SANs (GitHub's workflow identity; today they match emails only), so no signing secret remains
- [ ] Rebuild images built on coreos when coreos changes (a `workflow_run` trigger or a matrix) — no such image yet
- [ ] Bump nginx's base tag when nginx.org releases a new stable (by hand, or a bot that opens the change) — the daily build only follows rebuilds of the pinned tag
- [ ] An Open Graph image and structured data (JSON-LD) for the site — the placeholder carries the one line only
- [ ] Push trigger for more than one host (a list of targets, or an environment per host) — one host serves the site today
- [ ] Rotate the deploy key on a schedule (a new key pair, the host's `authorized_keys` and the repo secret) — no schedule yet
- [x] Name content images after the site they serve, not a generic `site` (several sites are planned): rename the `site/` folder, its package, the quadlet and the host's image list, and delete the old package — a note from the lead, not urgent
- [x] Run nginx's test when the site changes too (the site workflow pushes and deploys without it) — the test mounts `site/`, but only nginx's workflow runs it
- [ ] Per-address request or connection limits in nginx (`limit_req`, `limit_conn`) — a static site; a limit can hit many visitors behind one NAT address, so it needs numbers first
- [ ] Find out why a freshly pulled nginx image's layer has its `/etc` mtime changed, so `podman system check` calls it (and its image and container) damaged and `-r` would delete them — seen again in the user namespace right after a pull of a new nginx image: the layer's `diff/etc` and `diff` carry the pull's time, not the build's, so it looks like the layer's extraction, not the running container; until then never `-r` without restoring the mtime first (`touch -m -d @<the old one>` on the layer's `diff/etc`)
- [ ] Delete the old `site` package from ghcr.io (renamed; nothing pulls it any more) — the session's token lacks the `delete:packages` scope: an org owner in the package's settings (Danger Zone), or `gh auth refresh -s delete:packages` then `gh api -X DELETE /orgs/ai-bedrock/packages/container/site`
