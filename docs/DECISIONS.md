# Decisions

- D1. ai-fw runs llama.cpp only, no Ollama, Open WebUI or SearXNG
- D2. Vulkan, not ROCm, for llama.cpp on ai-fw
- D3. The llama.cpp API has no API key; it is reachable on the tailnet only
- D4. Models: Qwen3.6-35B-A3B and Qwen3.8-Flash-Next, not Qwen3-Coder-Next
- D5. Follow nixos-unstable: daily lock bump straight to main
- D6. bc-llm renamed to ai-fw
- D7. This repo is public
- D8. ai-fw carries only what a headless endpoint needs
- D9. Repo structure: explicit hosts and plain modules, no framework
- D10. bc-ws matches Bazzite DX NVIDIA, on NixOS
- D11. What was borrowed from other NixOS configs, and what was not
- D12. ai-fw installs from its own ISO; root has no password
- D13. LLM performance settings for the Framework Desktop
- D14. SSH: password login for brandon, no keys
- D15. Secure Boot deferred; Lanzaboote is ready on a branch

## D1. ai-fw runs llama.cpp only (2026-11-04)

ai-fw is an API endpoint for clients elsewhere, so it needs no chat UI or
web search. Removed Ollama, Open WebUI and SearXNG; port 8080 (opened for Open
WebUI on the LAN) is closed. llama.cpp over Ollama: newer model support
arrives there first, and llama-server's router serves several models from one
declarative preset.

## D2. Vulkan, not ROCm (2026-11-04)

A community Strix Halo benchmark set (strix-halo-guide, reviewed 2026-10-01)
has Vulkan/RADV ahead on token generation for MoE models (e.g. 19% on
Qwen3-Next 80B) and ROCm ahead on long-prompt processing. Interactive coding
is generation-bound. Revisit if the work becomes long-prompt or batch heavy;
for ROCm, the GPU is gfx1151 and current builds need no
`HSA_OVERRIDE_GFX_VERSION`.

## D3. No API key, tailnet only (2026-11-04)

Assumes every device on the tailnet is Brandon's (not checked when this was
written); the port is not open on the LAN. If anyone else's device is on the
tailnet, add `api-key-file` (a file outside the Nix store, passed with systemd
`LoadCredential`) or a Tailscale ACL.

## D4. Models (2026-11-04)

Qwen3-Coder-Next (Feb 2026) was the first choice. Two later Qwen releases beat
it on Qwen's own SWE-bench Pro scores, and one is also faster here:

| Model | Active | Strix Halo generation | SWE-bench Pro (vendor) |
|---|---|---|---|
| Qwen3-Coder-Next 80B | 3B | ~62 tok/s | 44.3 |
| Qwen3.6-35B-A3B | 3B | ~77–81 tok/s | 49.5 |
| Qwen3.8-Flash-Next 125B | 6B | ~29 tok/s | 62.5 |

Speeds are from strix-halo-guide's llama-bench tables, not measured on this
machine; scores are Qwen's own, from each model's Hugging Face card. Re-decide
with `llama-bench` and a few real tasks on ai-fw. Qwen3.8-Flash-Next's
licence is `qwen-community-1.0`, not Apache-2.0.

## D5. Follow nixos-unstable, daily lock bump to main (2026-11-04)

`system.autoUpgrade` with `flake = "github:…"` builds the committed lock and
never updates inputs; the lock sat at 2026-04-09 for seven months while
"auto-upgrade" was on.

Not a stable release: on 2026-11-04, nixos-26.05 had llama.cpp b9190 (May)
against unstable's v0.8.0 (Oct 28), older than any build known to run
Qwen3.8-Flash-Next. Its `linuxPackages_latest` matched unstable (7.3.1) and
Mesa was one minor version behind, so llama.cpp is the reason.

The first version of this decision was a weekly lock PR merged by hand. It
was replaced the same day by an unattended daily bump, because recovery is
covered without a person in the loop:

- the workflow evaluates and builds every host on the new lock and pushes
  nothing if one fails, so renamed options and broken packages never reach
  the box;
- both hosts have systemd-boot boot counting, so an entry that fails to boot 3
  times is skipped;
- both hosts keep 10 generations (the GC keeps exactly as many as the boot menu);
- every lock it ran is a commit on main, so a bad one can be reverted or
  bisected.

Not covered: a package that evaluates and boots but misbehaves (for example a
broken llama-server). That needs a manual rollback, within 10 generations.

The bump runs in CI rather than on the box (`--update-input` in the
auto-upgrade) so the lock ai-fw runs is always in git, and bc-ws gets the same
one. Uses `gh`/`git` on the runner rather than a lock-update Action, so the
only third-party Action is `cachix/install-nix-action` (Apache-2.0), pinned by
commit.

## D6. bc-llm renamed to ai-fw (2026-11-04)

Hostname, flake output, host folder and auto-upgrade target all changed. Not
carried over: the Tailscale/MagicDNS name follows the OS hostname on
Tailscale's next start only if it wasn't set by hand in the admin console;
clients and SSH config that say `bc-llm` must change to `ai-fw`.

A `nixosConfigurations.bc-llm` alias was added for an in-place switch (`nh os
switch` picks the config named after the current hostname) and removed the
same day: the machine is being reinstalled clean as `ai-fw`
(docs/runbooks/ai-fw-install.md), so nothing ever runs as `bc-llm` again.

## D7. This repo is public (2026-11-04)

ai-fw's auto-upgrade fetches `github:blconway/nixos-config`, which a private
repo answers with 404 unless the box holds a GitHub credential. Made public
rather than adding a deploy key: nothing to provision or rotate on the box,
and a clean install clones over plain HTTPS.

What being public exposes, checked across all 23 commits before the switch:
name, noreply email, SSH public keys (already public at
github.com/blconway.keys), hostnames, disk UUIDs and the network design (D3).
No passwords, tokens or private keys. Keep it that way: secrets live outside
the repo and outside the Nix store (as `/etc/secrets/searx-env` did).

If it ever goes private again, the auto-upgrade breaks silently. Switch
`system.autoUpgrade.flake` to `git+ssh://git@github.com/blconway/nixos-config#ai-fw`
with a read-only deploy key for root and GitHub's host key in
`programs.ssh.knownHosts`.

## D8. ai-fw carries only what a headless endpoint needs (2026-11-04)

Removed from ai-fw, and why each was safe to drop:

- **Home Manager**, and with it claude-code, fish, starship, bat, fzf, zoxide,
  eza, direnv, git config, btop and ncdu: nothing on the box is configured per
  user. `brandon` gets bash.
- **fail2ban:** SSH was key-only, so there was no password to guess. That
  reason collapsed with D14 (password login, no keys in use); fail2ban is
  back on ai-fw.
- **gnupg agent with SSH support, `nh`, `allowUnfree`:** workstation settings.
  They moved from `common.nix` to `modules/workstation.nix`, imported by bc-ws
  only; bc-ws's system derivation is byte-identical before and after. ai-fw
  evaluates without `allowUnfree`, so it uses no unfree packages.
- **`/etc/nixos` clone:** `update` is `sudo nixos-rebuild switch` from the
  same `github:` flake the nightly upgrade uses, so there is one source of
  what the box runs.
- **Docs, default packages (perl, rsync, strace), logrotate, udisks2, XDG
  bits:** `profiles/minimal.nix` from nixpkgs.

Measured on the 2026-11-03 lock: the system closure went from 4.69 GiB (874
store paths) to 4.02 GiB (602). Most of what is left is the kernel, firmware
and Mesa.

Kept on purpose: `radeontop`, `tmux`, `llama-cpp-vulkan` (for `llama-bench`,
D4), persistent journal, zram, port 22 on the LAN (the way in if Tailscale
breaks).

Rejected: `profiles/headless.nix`. It adds `nomodeset`, which disables the
amdgpu driver llama.cpp runs on, and turns off the tty1 console, the last way
in when the network is down.

## D9. Explicit hosts and plain modules, no framework (2026-11-04)

Two hosts, each `hosts/<host>/default.nix` importing the modules it uses
(`common`, a role like `workstation`, a service like `llm-server`). Considered
and not adopted: flake-parts, the dendritic pattern, numtide/blueprint, and
property-driven "broadcast-and-gate" module activation. Each solves wiring or
policy across many machines or platforms; with two hosts they add an input or
a layer of indirection, and what a host runs stops being readable from its own
file. Revisit at roughly four or more hosts, or a second platform (darwin).

## D10. bc-ws matches Bazzite DX NVIDIA, on NixOS (2026-11-04)

bc-ws is meant to run the same workload as a Bazzite DX NVIDIA install:
gaming plus development. The reference is what the images actually install
(ublue-os/bazzite README; ublue-os/bazzite-dx `build_files/20-install-apps.sh`
and `40-services.sh`), not a feature list from memory.

Added, as two role modules imported by bc-ws (D9):

- `modules/gaming.nix`: Steam with the Gamescope session, Steam Input on
  Wayland (extest), Proton-GE and protontricks; Gamescope; GameMode; xone and
  xpadneo controller drivers; Input Remapper; OBS with the Vulkan capture
  plugin; MangoHud, vkBasalt, ProtonUp-Qt.
- `modules/dev.nix`: Docker and Podman (both, no Podman docker shim, as in
  DX), Distrobox, libvirt with virt-manager, bcc and bpftrace/bpftop, sysprof,
  usbmuxd, android-tools, ccache, flatpak-builder, numactl, waypipe, restic,
  rclone, podman-tui, and nix-ld.
- `modules/nvidia.nix`: nvidia-container-toolkit, so containers get the GPU.
- `modules/workstation.nix`: fwupd.

Left out on purpose:

- **Waydroid:** with the proprietary NVIDIA driver it falls back to software
  rendering (WayDroid-ATV GPU FAQ), so on this box it would be slow.
- **ROCm** (DX installs it): AMD GPUs only.
- **Incus:** needs the nftables firewall backend, a change to the whole
  firewall for a tool nobody asked for. Add with `networking.nftables.enable`.
- **OpenRazer:** no Razer hardware is known on bc-ws.
- **sched-ext schedulers:** Bazzite supports them but leaves them off.
- **Bazzite's kernel (Open Gaming Collective):** nixpkgs doesn't package it.
  Its patch branches are mostly handheld hardware (Steam Deck, ASUS, Lenovo,
  MSI Claw, AYANEO, OneXPlayer, Zotac), which bc-ws doesn't have. Building it
  from source with `buildLinux` would compile the kernel and the NVIDIA, xone
  and xpadneo modules on every update, and take the CI build far past ten
  minutes. `linuxPackages_latest` is current; if a gaming-tuned kernel is
  ever wanted, nixpkgs has `linuxPackages_zen`, `_xanmod` and `_lqx`.
- **CachyOS's kernel:** would add a flake input (D9) for the same reasons.
- **Homebrew:** nix-ld covers running prebuilt binaries; packages come from
  nixpkgs.
- **Bazzite's preinstalled Flatpak apps** (OBS aside): personal app choices,
  installable through Bazaar.

Upgrades: bc-ws builds main's lock daily, never updates the lock itself, and
uses `operation = "boot"`. Switching a running session to a new NVIDIA driver
leaves the old kernel module loaded, which breaks GL and CUDA until a reboot,
so staging for the next boot is the same outcome without the broken window;
it is also how Bazzite applies updates. `update` pulls `/etc/nixos` and
switches immediately when you want it now.

NVIDIA branch: `latest` (615.x, NVIDIA's new-feature branch) rather than
nixpkgs `production` (595.x on 2026-11-04). Revisit if a driver regression
bites; `production` is one word in `modules/nvidia.nix`.

## D11. Borrowed from other NixOS configs, and what was not (2026-11-04)

Surveyed: wimpysworld/nix-config (972169f, whose two Framework Desktops run
llama.cpp on Vulkan like ai-fw), ryan4yin/nix-config (c4a00e5),
Misterio77/nix-starter-configs (fe4c4b1), numtide/blueprint (2bf1235),
mightyiam/dendritic (6c76240). Each claim below was checked against our
pinned nixpkgs, llama.cpp 0.8.0 or kernel source before it was used.

Borrowed:

- **`tests/invariants.nix`** (ryan4yin's eval tests, blueprint's `checks`
  layout): `nix flake check` fails, naming the decision, if an edit undoes a
  setting D1–D10 depend on.
- **`checks` and `formatter` outputs** (blueprint, starter configs):
  `nix flake check` replaced `.github/eval-hosts.sh`; `nix fmt` runs
  nixfmt-tree. One commit reformatted the repo with no change to either
  host's derivation.
- **Model-card sampling defaults** (Wimpress sets per-model samplers):
  llama-server's own defaults (top-k 40, min-p 0.05) are not what Qwen
  recommends, and OpenAI-style clients rarely send those two.
- **`llama-cpp-warmup`** (Wimpress pre-downloads models): a oneshot that asks
  each model "hi" through llama-server's own downloader. It adds only curl.
  Not verified: whether a request during a long download waits or returns
  5xx; curl retries for about 8 hours either way.
- **Dependabot for the pinned Actions** (Wimpress).
- **Closure diff in each lock commit** (ryan4yin runs it by hand before
  deploying).
- **No `system =` and no nix-channel** (starter configs): the platform comes
  from `nixpkgs.hostPlatform`; both hosts' derivations were identical without
  `system =`.

Measure on ai-fw before changing (not adopted yet):

- **zram:** ryan4yin saw zram deadlock as a model load neared physical RAM;
  on ai-fw the GPU's memory is that RAM. Load the 94 GB model and watch
  `zramctl` and `/proc/pressure/memory`.
- **mmap:** Wimpress turns it off on Strix Halo (`--load-mode none` in 0.8.0;
  their README's `--mmap 0` no longer exists). Compare with `llama-bench`.

Not borrowed:

- **`amdgpu.gpu_recovery=1`:** the default `-1` already enables recovery on
  everything but GCN 1.0 chips (`amdgpu_device_should_recover_gpu`).
- **"Dirty Frag" module blacklist (esp4, esp6, rxrpc):** fixed in the 7.0
  stable releases in May 2026; ai-fw runs 7.3.
- **journald size cap:** journald already caps itself at 10% of the disk or
  4 GB.
- **disko and nixos-anywhere:** a one-command install, for one flake input;
  the runbook covers a once-off install. Revisit if reinstalls become routine.
- **`programs.gamescope.capSysNice`, `split_lock_mitigate`:** capSysNice stays at
  the nixpkgs default until a game needs it; split_lock_mitigate is
  Intel-only, and bc-ws is AMD.
- **Kernel hardening sysctls:** against D8 for little gain on a tailnet box.
- **sops-nix/agenix, colmena/deploy-rs, monitoring stacks, host registries,
  haumea, llama-swap, custom ISOs, treefmt-nix, git-hooks.nix:** secrets we
  don't have, many-machine tooling, or a new input (D9).

## D12. ai-fw installs from its own ISO; root has no password (2026-11-04)

`nixosConfigurations.ai-fw-installer` is the NixOS minimal installer plus
`install-ai-fw`. Built on demand (`nix build .#ai-fw-installer-iso`), never
published; CI evaluates it on every PR but doesn't build the ~1.5 GB image.
This narrows D11's "no custom ISOs", which was about Wimpress-style daily
published images: one image built when needed replaces seven hand-typed steps,
two of them destructive, with one command at the installer's console (or
over SSH, after setting a temporary root password there).

Everything that must match ai-fw comes from ai-fw's own config, so the two
can't drift: the root and boot filesystem UUIDs (formatted to match
`hardware-configuration.nix`), the flake it installs
(`system.autoUpgrade.flake`), the `/boot` mount options, and the kernel. The script refuses to touch the disk until its name is typed back.

Root on ai-fw has no password, as on Ubuntu or Fedora: the config sets none
and the installer runs `nixos-install --no-root-passwd`, so `/etc/shadow`
holds a locked marker rather than a hash. Nothing random is generated. The way
in is `brandon` (SSH password, or the console) plus `sudo` with `brandon`'s
password; if that password is lost, boot the installer and reset it with
`nixos-enter`. `tests/invariants.nix` fails if a root password is ever
configured. bc-ws is unchanged: its root keeps whatever was set at install.

## D13. LLM performance settings for the Framework Desktop (2026-11-04)

Hardware, read from this machine under Windows before the reimage: Framework
Desktop, Ryzen AI Max+ 395 with Radeon 8060S, 127 GiB RAM, one WD SN850X 2 TB
NVMe, BIOS 03.06 with the GPU carve-out already at its 0.5 GiB minimum.

Source for the measured settings: hogeheer499-commits/strix-halo-guide
(MTP_SPECULATIVE_DECODING.md, STRIX_HALO_LOCAL_LLM_SETUP.md), Strix Halo
results only, read 2026-11-04.

Baked in:

- **Qwen3.6-35B-A3B with MTP speculative decoding** (`spec-type =
  draft-mtp`, `spec-draft-n-max = 2`): +18% (Q4_K_M) to +35% (IQ4_XS with Q8
  MTP head) generation on Vulkan. Needs the MTP layer, which
  `unsloth/Qwen3.6-35B-A3B-GGUF` strips and `unsloth/Qwen3.6-35B-A3B-MTP-GGUF`
  keeps (`blk.40.nextn.*`, checked in the file header). Same quant, +0.5 GB.
- **Flash attention on, mmap off (`load-mode = none`), `ubatch-size = 1024`**
  for every model: what all of the guide's measured runs use; 1024 was its
  best MTP result. Without mmap the 94 GB model isn't also held in the page
  cache in the same RAM.
- **Power:** what tuned's `accelerator-performance` profile sets, set
  directly: `performance` CPU governor, the firmware's `performance` ACPI
  platform profile when offered, `vm.swappiness = 10`. Not the tuned daemon
  itself (Python, and its default power-profiles support asserts upower; D8).

Measure on ai-fw before deciding (`llama-bench` and a real agent task):

- **MTP for Qwen3.8-Flash-Next** (Unsloth ships `MTP/mtp-*.gguf` drafts): the
  guide saw MTP make Qwen3-Next, the same hybrid design, 79% *slower* on
  Vulkan while it helped on ROCm; one unverified community report shows +106%.
- **ROCm for prompt processing:** the guide has ROCm 25–34% ahead at 16K
  prompts, Vulkan 18–30% ahead on generation. Agent work sends long prompts,
  so this may reverse D2 for one model.
- **zram** (D11), **q8_0 KV cache** (memory, not speed), **parallel slots**
  (left at auto), **thread count**.

Not adopted:

- **`amdgpu.cwsr_enable=0`:** the guide's workaround for a ROCm MES hang; ai-fw
  runs Vulkan.
- **`amd_iommu=off`:** the guide keeps it for one benchmark profile only and
  warns against it otherwise.
- **`amdgpu.gttsize`:** deprecated; `ttm.pages_limit` already sets the limit
  (112 GiB of the 127 GiB).

## D14. SSH: password login for brandon, no keys (2026-11-04)

The three keys at github.com/blconway.keys (copied into ai-fw on 2026-11-04)
have no private halves left in use, and the machine that ran the installer
test held none of them. So ai-fw takes SSH passwords instead, for `brandon`
only (`AllowUsers`), with root login off (root has no password anyway, D12).
fail2ban is back on: D8 dropped it because SSH was key-only, and that reason
no longer holds. Exposure: port 22 on the LAN and the tailnet, never the
internet. `tests/invariants.nix` fails if root SSH login is allowed, or if
passwords are accepted without fail2ban.

Revisit by adding a key to `users.users.brandon.openssh.authorizedKeys.keys`
and setting `PasswordAuthentication = false`; the installer then needs no
change.

## D15. Secure Boot deferred; Lanzaboote is ready on a branch (2026-11-04)

ai-fw boots with Secure Boot off: systemd-boot and the kernels aren't signed.
Wanted only if easy, and it wasn't finished to the bar of the rest: the boot
path changes right before the reinstall, and key generation and enrollment
had not run in a test.

Ready when wanted: branch `ai-fw-secure-boot` (commit 8c40304) adds
Lanzaboote v1.2.0 (nix-community, GPL-3.0) as a flake input following our
nixpkgs. Its module generates keys on first boot, stages them with
Microsoft's (the GPU option ROM needs those), and systemd-boot enrolls them on
the next boot in Setup Mode; boot counting (3 tries) and the 10-generation
limit stay. It evaluates and builds (`nix flake check` passes); a full ai-fw
build took 193 s on this machine, mostly compiling `lzbt` and fetching a Rust
toolchain, since nixpkgs has no `lzbt`. Before merging: run the installer VM
test with `OVMFFull` (Secure Boot firmware) through enrollment to an enforced
boot, and check the PR's CI time stays under ten minutes.

Considered: nixpkgs' own `boot.loader.limine.secureBoot` (sbctl key
generation and enrollment, no extra input, nothing compiled). Not chosen
because limine has no automatic boot assessment, and boot counting is how an
unattended upgrade that doesn't boot rolls itself back (D5).

Turning it on later also needs a BIOS password, or Secure Boot can simply be
switched off again by anyone at the machine.
