{ config, pkgs, lib, ... }:

let
  # Models the llama-server router offers. A section name is what a client
  # sends as "model"; keys are llama-server flags without the leading dashes.
  # Files download from Hugging Face on a model's first load into
  # /var/cache/llama-cpp.
  modelsPreset = pkgs.writeText "llama-models.ini" (lib.generators.toINIWithGlobalSection { } {
    globalSection = { version = 1; };
    sections = {
      # Fast default: ~22 GB, 3B active.
      "qwen3.6-35b-a3b" = {
        hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL";
      };
      # Strongest that fits: ~94 GB, 6B active, thinks by default.
      "qwen3.8-flash-next" = {
        hf-repo = "unsloth/Qwen3.8-Flash-Next-GGUF:UD-IQ4_XS";
      };
    };
  });
in
{
  # ============================================================
  # llama.cpp — OpenAI-compatible inference endpoint
  # ============================================================
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan;  # Vulkan (RADV) beats ROCm on token generation on Strix Halo
    settings = {
      host = "0.0.0.0";  # tailnet only: the port is not opened on the LAN
      port = 8080;
      models-preset = "${modelsPreset}";
      # Both models together (~116 GB) don't fit beside a KV cache, so the
      # router unloads one to load the other.
      models-max = 1;
    };
  };
}
