# Decisions

- D1. ai-fw runs llama.cpp only, no Ollama, Open WebUI or SearXNG
- D2. Vulkan, not ROCm, for llama.cpp on ai-fw
- D3. The llama.cpp API has no API key; it is reachable on the tailnet only
- D4. Models: Qwen3.6-35B-A3B and Qwen3.8-Flash-Next, not Qwen3-Coder-Next
- D5. Follow nixos-unstable: daily lock bump straight to main
- D6. bc-llm renamed to ai-fw

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

- the workflow evaluates every host on the new lock and pushes nothing if one
  fails, so renamed or removed options never reach the box;
- ai-fw has systemd-boot boot counting, so an entry that fails to boot 3
  times is skipped;
- ai-fw keeps 10 generations (the GC keeps exactly as many as the boot menu);
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

`nixosConfigurations.bc-llm` stays as an alias of `ai-fw` because the machine
still has hostname `bc-llm` until it switches, and `update` (`nh os switch`)
picks the config named after the current hostname. Remove the alias once
`hostname` on the machine prints `ai-fw`.
