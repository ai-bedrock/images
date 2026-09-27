# images

Container and OS images, one folder each, built by GitHub Actions, signed, and published as `ghcr.io/ai-bedrock/<folder>` with the tags `stable`, `<yyyymmdd>` and `base-<digest of the base image>`.

| image | what it is |
|---|---|
| [coreos](coreos/) | Fedora CoreOS stable plus a thin host layer: key-only SSH, a firewall with inbound SSH, HTTP and HTTPS only, signed images only from this namespace, automatic updates in a daily reboot window |

## Verifying a signature

Every pushed tag carries a sigstore signature (a sigstore attachment next to the image) made with one key pair; the public key is [coreos/rootfs/etc/pki/containers/ai-bedrock-images.pub](coreos/rootfs/etc/pki/containers/ai-bedrock-images.pub). With podman:

```sh
mkdir -p ~/.config/containers/registries.d
cp coreos/rootfs/etc/containers/registries.d/ghcr.io-ai-bedrock.yaml ~/.config/containers/registries.d/
sudo install -D -m 0644 coreos/rootfs/etc/pki/containers/ai-bedrock-images.pub /etc/pki/containers/ai-bedrock-images.pub
podman pull --signature-policy coreos/rootfs/etc/containers/policy.json ghcr.io/ai-bedrock/coreos:stable
```

An unsigned or differently signed image is refused ("A signature was required, but no signature exists" / "cryptographic signature verification failed"). The coreos image ships the same policy, so hosts running it check every image under `ghcr.io/ai-bedrock` the same way.
