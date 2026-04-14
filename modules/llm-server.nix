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
    loadModels = [
      "qwen3:235b-q3_K_M"         # primary — best quality, ~105GB, ~3-5 t/s
      "qwen3:72b-q8_0"            # fast — quick questions and coding, ~72GB, ~10-15 t/s
    ];
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
      ENABLE_RAG_WEB_SEARCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://127.0.0.1:8888/search?q=<query>&format=json";
      WEBUI_AUTH = "True";
      # STT — built-in Whisper (no extra service needed)
      AUDIO_STT_ENGINE = "";
      WHISPER_MODEL = "large-v3";
      WHISPER_COMPUTE_TYPE = "float16";
      # TTS — Kokoro FastAPI container
      AUDIO_TTS_ENGINE = "openai";
      AUDIO_TTS_OPENAI_API_BASE_URL = "http://127.0.0.1:8880/v1";
      AUDIO_TTS_OPENAI_API_KEY = "not-needed";
    };
  };

  # ============================================================
  # Kokoro FastAPI — local text-to-speech (OpenAI-compatible)
  # ============================================================
  virtualisation.podman.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";
    containers.kokoro-tts = {
      image = "ghcr.io/remsky/kokoro-fastapi-cpu:latest";
      ports = [ "127.0.0.1:8880:8880" ];
      environment = {
        PYTHONUNBUFFERED = "1";
      };
    };
  };

  # ============================================================
  # SearXNG — meta-search engine for RAG web search
  # ============================================================
  services.searx = {
    enable = true;
    redisCreateLocally = true;
    settings = {
      server = {
        port = 8888;
        bind_address = "127.0.0.1";  # local only; Open WebUI proxies
        secret_key = "@SEARX_SECRET_KEY@";
      };
      search = {
        formats = [ "html" "json" ];
      };
    };
    environmentFile = "/etc/secrets/searx-env";
  };
}
