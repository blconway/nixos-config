# Decisions

- D1. bc-llm runs llama.cpp only, no Ollama, Open WebUI or SearXNG
- D2. Vulkan, not ROCm, for llama.cpp on bc-llm
- D3. The llama.cpp API has no API key; it is reachable on the tailnet only
- D4. Models: Qwen3.6-35B-A3B and Qwen3.8-Flash-Next, not Qwen3-Coder-Next
- D5. flake.lock is updated by a weekly PR, not by the auto-upgrade

## D1. bc-llm runs llama.cpp only (2026-11-04)

bc-llm is an API endpoint for clients elsewhere, so it needs no chat UI or
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
with `llama-bench` and a few real tasks on bc-llm. Qwen3.8-Flash-Next's
licence is `qwen-community-1.0`, not Apache-2.0.

## D5. Weekly lock-update PR (2026-11-04)

`system.autoUpgrade` with `flake = "github:…"` builds the committed lock and
never updates inputs; the lock sat at 2026-04-09 for seven months while
"auto-upgrade" was on. A weekly workflow runs `nix flake update`, evaluates
both hosts, and opens a PR. Merging stays manual because it deploys bc-llm
unattended. Uses `gh` on the runner rather than a lock-update Action, so the
only third-party Action is `cachix/install-nix-action` (Apache-2.0), pinned by
commit.
