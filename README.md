# images

Container and OS images, one folder each, built by GitHub Actions, signed, and published as `ghcr.io/ai-bedrock/<folder>` with the tags `stable`, `<yyyymmdd>` and `base-<digest of the base image>`.

| image | what it is |
|---|---|
| [coreos](coreos/) | Fedora CoreOS stable plus a thin host layer: key-only SSH, a firewall with inbound SSH, HTTP and HTTPS only and no metadata service after the first boot, signed images only from this namespace, automatic updates in a daily reboot window |
| [nginx](nginx/) | nginx (official unprivileged image) plus its ACME module: one static site over HTTPS with a certificate it obtains and renews itself |
| [site](site/) | the website's static files only (`FROM scratch`), mounted read-only into nginx; a site change ships only this image |

## Verifying a signature

Every pushed tag carries a sigstore signature (a sigstore attachment next to the image) made with one key pair; the public key is [coreos/rootfs/etc/pki/containers/ai-bedrock-images.pub](coreos/rootfs/etc/pki/containers/ai-bedrock-images.pub). With podman:

```sh
mkdir -p ~/.config/containers/registries.d
cp coreos/rootfs/etc/containers/registries.d/ghcr.io-ai-bedrock.yaml ~/.config/containers/registries.d/
sudo install -D -m 0644 coreos/rootfs/etc/pki/containers/ai-bedrock-images.pub /etc/pki/containers/ai-bedrock-images.pub
podman pull --signature-policy coreos/rootfs/etc/containers/policy.json ghcr.io/ai-bedrock/coreos:stable
```

An unsigned or differently signed image is refused ("A signature was required, but no signature exists" / "cryptographic signature verification failed"). The coreos image ships the same policy, so hosts running it check every image under `ghcr.io/ai-bedrock` the same way.

## Deploying on push

The site and nginx workflows end with a push trigger: CI logs in over SSH as the host's `deploy` user and sends the name of the image it just pushed; the host pulls it (signature-checked) and restarts what uses it (coreos README: `deploy`, `image-update`). Repo secrets: `DEPLOY_HOST` (the host's name), `DEPLOY_KNOWN_HOSTS` (its SSH host key line), `DEPLOY_SSH_KEY` (the private key whose public half is in the host's `/etc/image-update/authorized_keys`). Without `DEPLOY_HOST` the step does nothing, and the host's daily update picks the image up.
