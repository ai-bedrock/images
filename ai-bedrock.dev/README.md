# ai-bedrock.dev

The website's static files and nothing else (`FROM scratch`): `ghcr.io/ai-bedrock/ai-bedrock.dev`, named after the site's domain. It runs nothing; a web server mounts it read-only as its document root, so a change to the site builds and ships only this image.

```sh
podman run -d ... --mount type=image,source=ghcr.io/ai-bedrock/ai-bedrock.dev:stable,destination=/usr/share/nginx/html ghcr.io/ai-bedrock/nginx:stable
```

In a Podman quadlet: an `ai-bedrock.dev.image` unit (`Image=ghcr.io/ai-bedrock/ai-bedrock.dev:stable`) and `Mount=type=image,source=ai-bedrock.dev.image,destination=/usr/share/nginx/html` in the container unit (in a user namespace, a volume backed by the image instead), which then pulls the site before it starts. `podman auto-update` doesn't follow a mounted image; the coreos image's `image-update` does (push trigger and daily).

## Its test

`test.sh <image>` serves the image with the registry's current `nginx:stable` through [nginx's test](../nginx/README.md#its-test), so a site change is checked by the same test before its push and deploy. It is not part of the image.

## Every file

- `Containerfile`: `FROM scratch`, copies `public/` to `/`, its own title and description labels
- `public/index.html`: the page: title, description, canonical URL, the logo inline, one line, a link to the project's code
- `public/404.html`: the not-found page (served with status 404, not indexed)
- `public/style.css`: the pages' only styles (light and dark)
- `public/robots.txt`: everything allowed, and where the sitemap is
- `public/sitemap.xml`: the one page
- `public/favicon.svg`, `public/favicon-32.png`, `public/apple-touch-icon.png`: the logo as icons (SVG, 32 px, 180 px)
