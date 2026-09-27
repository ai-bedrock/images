# coreos

Fedora CoreOS stable plus a thin host layer: `ghcr.io/ai-bedrock/coreos`.

**This image is public: nothing private goes in it.** No keys (other than the public signing key), tokens, passwords, IPs, hostnames, names or account details. Per-host and secret values come in at creation through Ignition (user-data), never through this directory.

Everything it changes against upstream:

- `rootfs/etc/ssh/sshd_config.d/10-hardening.conf`: key-only SSH (`AuthenticationMethods publickey`), `AllowUsers core`, no root login, no password, keyboard-interactive or GSSAPI, no X11
- `rootfs/etc/sysconfig/nftables.conf`: the host firewall, its own `inet host` table with policy drop; established, loopback, ICMP, DHCP replies and TCP 22, 80 and 443 in
- `rootfs/etc/systemd/resolved.conf.d/10-no-multicast.conf`: no LLMNR or mDNS listeners
- `rootfs/etc/zincati/config.d/90-image-updates.toml`: Zincati off, because it follows Fedora's update graph and not this image's tag
- `rootfs/etc/systemd/system/bootc-fetch-apply-updates.timer.d/10-window.conf`: bootc's update timer runs daily at 03:30 UTC plus up to 30 minutes, and reboots only when a new image was staged
- `rootfs/etc/containers/policy.json`: images under `ghcr.io/ai-bedrock` only when signed with the key below (sigstore); anything else as upstream (accepted unchecked); used by podman, rpm-ostree and bootc
- `rootfs/etc/containers/registries.d/ghcr.io-ai-bedrock.yaml`: look for those signatures as sigstore attachments on the registry
- `rootfs/etc/pki/containers/ai-bedrock-images.pub`: the public half of the signing key
- `Containerfile`: enables `nftables.service` and `bootc-fetch-apply-updates.timer`, then runs `bootc container lint`

A host switches to it signature-checked with `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ai-bedrock/coreos:stable` (or `bootc switch --enforce-container-sigpolicy`), once the policy files above are in its `/etc`.
