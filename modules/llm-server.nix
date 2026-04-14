{ config, pkgs, ... }:

{
  # ============================================================
  # Ollama — LLM inference engine
  # ============================================================
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;  # Vulkan outperforms ROCm on Strix Halo
    host = "0.0.0.0";
    port = 11434;
    openFirewall = false;          # only accessible via tailnet (trustedInterfaces)
    # Models are large — pull manually with `ollama pull` rather than on boot.
    # To switch to ROCm, uncomment below and comment out ollama-vulkan above:
    # package = pkgs.ollama-rocm;
    # rocmOverrideGfx = "11.5.0";
  };

  # ============================================================
  # Open WebUI — chat interface for LLMs
  # ============================================================
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    openFirewall = false;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "True";
    };
  };
}
