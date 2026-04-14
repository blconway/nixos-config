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
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      ENABLE_RAG_WEB_SEARCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://127.0.0.1:8888/search?q=<query>&format=json";
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
    environmentFile = "/run/secrets/searx-env";
  };
}
