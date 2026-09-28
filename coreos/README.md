# coreos

Fedora CoreOS stable plus a thin host layer: `ghcr.io/ai-bedrock/coreos`.

**This image is public: nothing private goes in it.** No keys (other than the public signing key), tokens, passwords, IPs, hostnames, names or account details. Per-host and secret values come in at creation through Ignition (user-data), never through this directory.

Everything it changes against upstream:

- `rootfs/etc/ssh/sshd_config.d/10-hardening.conf`: key-only SSH (`AuthenticationMethods publickey`), `AllowUsers core deploy`, no root login, no password, keyboard-interactive or GSSAPI, no X11; its own crypto ahead of the system policy (ML-KEM hybrid or X25519 key exchange, AEAD ciphers, encrypt-then-MAC, the ed25519 host key only); no agent, remote port or socket forwarding (local `-L` stays), no compression or rc file; dead clients dropped after 10 minutes; `LogLevel VERBOSE` (each login's key fingerprint); the `deploy` user gets one forced command (below), its keys only from the root-owned `/etc/image-update/authorized_keys`, no pty, forwarding, tunnel or rc file, and a connection that opens no session closes after 30 s
- `rootfs/etc/sysconfig/nftables.conf`: the host firewall, its own `inet host` table: inbound policy drop with established, loopback, ICMP, DHCP replies and TCP 22, 80 and 443 in; new SSH connections limited per source address (15 a minute, bursts of 30; over it they're dropped); the cloud metadata service (169.254.169.254, fe80::a9fe:a9fe) rejected from the host and from containers (output and forward chains), since it serves the user-data and only the first boot, before this image, needs it
- `rootfs/etc/systemd/system/afterburn-sshkeys@.service.d/10-off.conf`: Afterburn no longer fetches SSH keys from the metadata service at each boot (unless the kernel command line has `afterburn.sshkeys`); the keys come from Ignition
- `rootfs/etc/systemd/resolved.conf.d/10-no-multicast.conf`: no LLMNR or mDNS listeners
- `rootfs/etc/sysctl.d/90-hardening.conf`: no ICMP redirects accepted or sent, kernel pointers hidden (`kptr_restrict`), ptrace of own children only (`yama.ptrace_scope`), no setuid core dumps, hardened BPF JIT, kexec disabled
- `rootfs/etc/zincati/config.d/90-image-updates.toml`: Zincati off, because it follows Fedora's update graph and not this image's tag; the `Containerfile` also disables its service
- `rootfs/etc/systemd/system/bootc-fetch-apply-updates.timer.d/10-window.conf`: bootc's update timer runs daily at 03:30 UTC plus up to 30 minutes, and reboots only when a new image was staged
- `rootfs/etc/containers/policy.json`: images under `ghcr.io/ai-bedrock` only when signed with the key below (sigstore); anything else accepted unchecked as upstream, spelled per transport with a default of `reject`, since bootc refuses a signature-checked reference while the default is `insecureAcceptAnything`; used by podman, rpm-ostree and bootc
- `rootfs/etc/containers/registries.d/ghcr.io-ai-bedrock.yaml`: look for those signatures as sigstore attachments on the registry
- `rootfs/etc/pki/containers/ai-bedrock-images.pub`: the public half of the signing key
- `rootfs/usr/lib/sysusers.d/deploy.conf`: the `deploy` user (no password, home `/`), which CI logs in as to trigger an image update
- `rootfs/usr/libexec/ai-bedrock/deploy`: the deploy user's forced command: reads image names (lower case, single spaces) from `SSH_ORIGINAL_COMMAND`, refuses the whole request (exit 2, logged) unless each is literally a name in `/etc/image-update/images`, then starts `image-update@<name>.service` for each and echoes its result line
- `rootfs/usr/share/polkit-1/rules.d/50-deploy.rules`: lets the deploy user start `image-update@<name>.service`, nothing else
- `rootfs/usr/libexec/ai-bedrock/image-update`: pulls the named images (or all) listed in `/etc/image-update/images` (`<name> <reference> <unit>...` per line, per host, from Ignition) through the signature policy and restarts their units when an image changed; logs `<name> <digest> <what it did>`
- `rootfs/usr/lib/systemd/system/image-update@.service`: one image's update, as root (what the deploy command starts)
- `rootfs/usr/lib/systemd/system/image-update.service`, `image-update.timer`: every listed image daily at 00:30 UTC plus up to 30 minutes, in case a push trigger was missed; nothing without `/etc/image-update/images`
- `Containerfile`: enables `nftables.service`, `bootc-fetch-apply-updates.timer` and `image-update.timer`, disables `zincati.service`, then runs `bootc container lint`

A host switches to it signature-checked with `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ai-bedrock/coreos:stable` (or `bootc switch --enforce-container-sigpolicy`), once the policy files above are in its `/etc`.
