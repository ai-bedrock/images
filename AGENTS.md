# images

ai-bedrock's container and OS images: one folder per image, each built, signed and pushed by CI to `ghcr.io/ai-bedrock/<folder>`.

- the project lead leads the design: ask how they'd approach something before proposing your own; name ideas you're holding back in one line instead of building them
- KISS; novel over familiar, but say which parts are novel
- **this repo and its images are public: nothing private goes in them.** No keys (other than the public signing key), tokens, passwords, IPs, hostnames, domains, names, account or provider details, in files, image labels, build logs or commit messages; per-host and secret values come in at creation, never through an image
- content images (a site's files) carry their site's own public domain as their name, dots kept: folder, workflow and package; the one exception to the no-domains rule, for this project's own sites only, and only as that name
- every file an image adds or changes is listed in that image's README.md, one line each
- images are signed in CI; hosts accept images under this registry namespace only with that signature
- `docs/decisions.md` and `docs/later.md` are this repo's public record of its decisions and deferrals, updated at release; work in progress is filed in the workbench's own store, which is not in this repo
- atomic conventional commits, no emojis

## Mechanics

- tool config lives in `.config/` (mise), caches in `.config/.local/`, local scratch in `/.work/` (git-ignored); `mise run` lists tasks
- `mise run check` green before every commit: hadolint, actionlint, shellcheck
- a new image: a folder with a Containerfile and README.md, and a workflow calling `.github/workflows/build.yml` with its path filter (copy `coreos.yml`); images built on another image here say `FROM ghcr.io/ai-bedrock/<it>:stable`
- no roles of its own yet: agents work from this file

## In a workbench

When this repo is a nested clone in a workbench, the workbench holds everything personal: handoffs, the feed, the lead's words, and whatever uses these images. Nothing of that lands here.
