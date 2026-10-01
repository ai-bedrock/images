# later

One line per item: `- [ ] <what> — <why it waits>`. Tick it or delete it when done.

- [ ] Keyless signing (Fulcio + Rekor through the workflow's OIDC identity) instead of the key pair, once containers/image policies match certificate URI SANs (GitHub's workflow identity; today they match emails only), so no signing secret remains
- [ ] Rebuild images built on coreos when coreos changes (a `workflow_run` trigger or a matrix) — no such image yet
- [x] Bump nginx's base tag when nginx.org releases a new stable (by hand, or a bot that opens the change) — the daily build only follows rebuilds of the pinned tag
- [ ] An Open Graph image and structured data (JSON-LD) for the site — the placeholder carries the one line only
- [ ] Push trigger for more than one host (a list of targets, or an environment per host) — one host serves the site today
- [ ] Rotate the deploy key on a schedule (a new key pair, the host's `authorized_keys` and the repo secret) — no schedule yet
- [x] Name content images after the site they serve, not a generic `site` (several sites are planned): rename the `site/` folder, its package, the quadlet and the host's image list, and delete the old package — a note from the lead, not urgent
- [x] Run nginx's test when the site changes too (the site workflow pushes and deploys without it) — the test mounts `site/`, but only nginx's workflow runs it
- [ ] Per-address request or connection limits in nginx (`limit_req`, `limit_conn`) — a static site; a limit can hit many visitors behind one NAT address, so it needs numbers first
- [ ] Drop `touch /etc` from nginx's RUN once CI's podman builds with buildah 2e54afcba (unreleased after 1.45.1; it keeps a RUN mount target's parent directory in the layer) — until then the touch keeps `/etc` in the layer, so a pull doesn't recreate it with the pull's time and `podman system check` doesn't call the layer damaged; an image built before the touch still shows it: restore the layer's `diff/etc` mtime (`touch -m -d @<the lower layer's>`) or pull a newer build before any `-r`
- [ ] Delete the old `site` package from ghcr.io (renamed; nothing pulls it any more) — the session's token lacks the `delete:packages` scope: an org owner in the package's settings (Danger Zone), or `gh auth refresh -s delete:packages` then `gh api -X DELETE /orgs/ai-bedrock/packages/container/site`
- [ ] Let Actions open pull requests in the organization (Settings, Actions, General: "Allow GitHub Actions to create and approve pull requests", then the same in this repo), so nginx-bump opens its pull request itself instead of an issue — needs an org owner (the session's token lacks `admin:org`)
