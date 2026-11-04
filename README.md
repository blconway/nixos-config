# nixos-config

NixOS flake for two machines: `bc-ws` (GNOME workstation, NVIDIA) and `ai-fw`
(Framework Desktop, Ryzen AI Max 300, run as a headless llama.cpp endpoint).
Both follow nixos-unstable.

## Run it

Check a change before deploying it, from any machine with Nix:

```sh
./.github/eval-hosts.sh                      # evaluates every host, builds nothing
nixos-rebuild build --flake .#ai-fw          # full build, from bc-ws
```

Deploy: push to `main`. ai-fw upgrades itself at 04:10 from GitHub and
reboots inside 04:00–06:00 when the kernel changed. To deploy now, on the
machine run `update` (fish alias: resets `/etc/nixos` to `origin/main`, then
rebuilds). Local uncommitted changes on ai-fw are overwritten by the next
auto-upgrade, so commit and push instead.

New packages arrive only through `flake.lock`. The `flake` workflow updates
it daily at 10:00 UTC and commits it to `main` once every host evaluates, so
ai-fw runs nixos-unstable about a day behind. bc-ws picks it up on its next
`rebuild`.

## When it breaks

- **ai-fw doesn't come back after an upgrade:** a new boot entry that fails 3
  times is skipped automatically. If it boots but something is broken, over
  SSH: `sudo nixos-rebuild switch --rollback`, or pick an older entry in the
  boot menu (keyboard and monitor). 10 generations are kept. Then revert or
  fix it on `main`, or the next 04:10 upgrade puts it back.
- **A bad lock reached `main`:** `git revert` the "Update flake.lock" commit
  and push; ai-fw takes the revert at 04:10, or run `update`. The next daily
  bump will bring the newer inputs back, so pin or fix before then.
- **The daily bump failed:** the workflow run is red and nothing was pushed.
  Its log shows which host failed to evaluate.

## ai-fw

OpenAI-compatible API at `http://ai-fw:8080/v1`, tailnet only. Models
(`model` field): `qwen3.6-35b-a3b` (fast default) and `qwen3.8-flash-next`
(strongest, ~94 GB). Only one is loaded at a time; switching unloads the other.
Each model downloads on its first load, so that request is slow.

```sh
curl http://ai-fw:8080/v1/models
```

### Fresh install, by hand

Nix doesn't do these:

1. BIOS: set the iGPU memory carve-out (UMA frame buffer) to its minimum. The
   GPU then uses GTT, sized by `boot.kernelParams` in `hosts/ai-fw/default.nix`.
2. `sudo tailscale up` and approve the machine in the Tailscale admin console.
3. Clone this repo to `/etc/nixos`, then `rebuild`.
4. Check the GPU memory limit took effect (expect 120259084288 bytes, 112 GiB):
   `cat /sys/class/drm/card*/device/mem_info_gtt_total`
5. Load each model once to download it:
   `curl http://localhost:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{"model":"qwen3.6-35b-a3b","messages":[{"role":"user","content":"hi"}]}'`

Left over from before 2026-11 and safe to delete: `/var/lib/private/ollama`
(Ollama models), `/var/lib/open-webui`, `/etc/secrets/searx-env`.

## Layout

| Path | What |
|---|---|
| `flake.nix` | Hosts and inputs |
| `hosts/<host>/` | Per-machine config, hardware config, Home Manager config |
| `modules/` | Shared NixOS modules |
| `home/` | Shared Home Manager config |
| `docs/DECISIONS.md` | What was decided and why |
| `.github/` | CI: host evaluation and the daily lock update |
