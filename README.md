# nixos-config

NixOS flake for two machines: `bc-ws` (GNOME workstation, NVIDIA) and `bc-llm`
(Framework Desktop, Ryzen AI Max 300, run as a headless llama.cpp endpoint).

## Run it

Check a change before deploying it, from any machine with Nix:

```sh
./.github/eval-hosts.sh                      # evaluates both hosts, builds nothing
nixos-rebuild build --flake .#bc-llm         # full build, from bc-ws
```

Deploy: push to `main`. bc-llm upgrades itself at 04:10 from GitHub and
reboots inside 04:00–06:00 when the kernel changed. To deploy now, on the
machine run `update` (fish alias: resets `/etc/nixos` to `origin/main`, then
rebuilds). Local uncommitted changes on bc-llm are overwritten by the next
auto-upgrade, so commit and push instead.

New packages arrive only through `flake.lock`. The `flake` workflow opens a
lock-update PR every Monday, after evaluating both hosts on the new lock.

## bc-llm

OpenAI-compatible API at `http://bc-llm:8080/v1`, tailnet only. Models
(`model` field): `qwen3.6-35b-a3b` (fast default) and `qwen3.8-flash-next`
(strongest, ~94 GB). Only one is loaded at a time; switching unloads the other.
Each model downloads on its first request, so that request is slow.

```sh
curl http://bc-llm:8080/v1/models
```

### Fresh install, by hand

Nix doesn't do these:

1. BIOS: set the iGPU memory carve-out (UMA frame buffer) to its minimum. The
   GPU then uses GTT, sized by `boot.kernelParams` in `hosts/bc-llm/default.nix`.
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
| `.github/` | CI: host evaluation and the weekly lock update |
