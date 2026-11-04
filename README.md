# nixos-config

NixOS flake for two machines: `bc-ws` (GNOME gaming and development
workstation, NVIDIA, roughly Bazzite DX) and `ai-fw`
(Framework Desktop, Ryzen AI Max 300, run as a headless llama.cpp endpoint).
Both follow nixos-unstable.

## Run it

Check a change before deploying it, from any machine with Nix:

```sh
nix flake check --no-build    # evaluates both hosts and tests/invariants.nix
nix fmt                       # formats every .nix file (CI fails on unformatted)
nix flake check               # the same, plus a full build of both hosts
```

`tests/invariants.nix` fails, naming the decision, if an edit undoes a
setting a decision in `docs/DECISIONS.md` depends on.

Deploy: push to `main`. ai-fw upgrades itself at 04:10 from GitHub and
reboots inside 04:00–06:00 when the kernel changed. To deploy now, on the
machine run `update` (`sudo nixos-rebuild switch` from the same GitHub flake).
ai-fw has no local clone: everything it runs comes from `main`.

New packages arrive only through `flake.lock`. The `flake` workflow updates
it daily at 10:00 UTC and commits it to `main` once every host builds, so
ai-fw runs nixos-unstable about a day behind. bc-ws builds the same lock
daily and stages it for its next reboot (`update` there pulls `/etc/nixos`
and switches now). Each lock commit's message lists what changed on each
host (`nix store diff-closures`), so a bad one is easy to find.

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
  Its log shows which host failed to evaluate or build.

## ai-fw

OpenAI-compatible API at `http://ai-fw:8080/v1`, tailnet only. Models
(`model` field): `qwen3.6-35b-a3b` (fast default) and `qwen3.8-flash-next`
(strongest, ~94 GB). Only one is loaded at a time; switching unloads the other.
`llama-cpp-warmup` downloads both after an install and, on every boot, asks
each one "hi"; `systemctl status llama-cpp-warmup` says whether they answered.
Sampling defaults are each model's card values; a client's own settings win.

```sh
curl http://ai-fw:8080/v1/models
```

Clean install: [docs/runbooks/ai-fw-install.md](docs/runbooks/ai-fw-install.md).

## Layout

| Path | What |
|---|---|
| `flake.nix` | Hosts and inputs |
| `hosts/<host>/` | Per-machine config, hardware config, and Home Manager config where the host has one (bc-ws) |
| `modules/` | Shared NixOS modules |
| `home/` | Shared Home Manager config |
| `docs/DECISIONS.md` | What was decided and why |
| `docs/runbooks/` | How to do a job, one file each |
| `tests/` | `invariants.nix`, run by `nix flake check` |
| `.github/` | CI (checks, formatting, builds every host; the daily lock update) and Dependabot for the pinned Actions |
