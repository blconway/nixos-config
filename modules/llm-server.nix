{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Models the llama-server router offers, in warm-up order (the last one
  # stays loaded). `name` is what a client sends as "model"; the other keys
  # are llama-server flags without the leading dashes. Sampling values are
  # the defaults each model's Hugging Face card recommends; a client that
  # sends its own still wins. OpenAI-style clients rarely send top-k or
  # min-p, so without these the server's 40 and 0.05 would apply.
  models = [
    {
      # Strongest that fits: ~94 GB, 6B active, thinks by default.
      # Card: thinking mode.
      name = "qwen3.8-flash-next";
      hf-repo = "unsloth/Qwen3.8-Flash-Next-GGUF:UD-IQ4_XS";
      temp = "1.0";
      top-p = "0.95";
      top-k = "20";
      min-p = "0.0";
      presence-penalty = "0.0";
      fit-ctx = "131072"; # card: final answers up to 131072 tokens
    }
    {
      # Fast default: ~22 GB, 3B active. Card: thinking mode, precise coding.
      name = "qwen3.6-35b-a3b";
      hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL";
      temp = "0.6";
      top-p = "0.95";
      top-k = "20";
      min-p = "0.0";
      presence-penalty = "0.0";
      fit-ctx = "131072"; # card: keep at least 128K to preserve thinking
    }
  ];

  # Files download from Hugging Face on a model's first load into
  # /var/cache/llama-cpp.
  modelsPreset = pkgs.writeText "llama-models.ini" (
    lib.generators.toINIWithGlobalSection { } {
      globalSection = {
        version = 1;
      };
      sections = lib.listToAttrs (map (m: lib.nameValuePair m.name (removeAttrs m [ "name" ])) models);
    }
  );

  port = toString config.services.llama-cpp.settings.port;
in
{
  # ============================================================
  # llama.cpp — OpenAI-compatible inference endpoint
  # ============================================================
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp-vulkan; # Vulkan (RADV) beats ROCm on token generation on Strix Halo
    settings = {
      host = "0.0.0.0"; # tailnet only: the port is not opened on the LAN
      port = 8080;
      models-preset = "${modelsPreset}";
      # Both models together (~116 GB) don't fit beside a KV cache, so the
      # router unloads one to load the other.
      models-max = 1;
    };
  };

  # ============================================================
  # Warm-up: download and answer once with each model
  # ============================================================
  # After a fresh install this downloads both models (~116 GB) without anyone
  # asking, and on every boot it proves each model loads and answers. A
  # failure shows in `systemctl --failed`; `journalctl -u llama-cpp-warmup`
  # has the response.
  systemd.services.llama-cpp-warmup = {
    description = "Download and test each llama.cpp model once";
    wantedBy = [ "multi-user.target" ];
    requires = [ "llama-cpp.service" ];
    after = [
      "llama-cpp.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    path = [ pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      TimeoutStartSec = "infinity"; # the first download can take hours
    };
    script = lib.concatMapStrings (m: ''
      echo "warming ${m.name}"
      # Retries on refused connections and 5xx while the server starts or a
      # model downloads: up to ~8 hours, for a ~94 GB first download.
      curl --fail --silent --show-error \
        --retry 1000 --retry-delay 30 --retry-connrefused \
        http://127.0.0.1:${port}/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{"model":"${m.name}","messages":[{"role":"user","content":"hi"}],"max_tokens":1}'
      echo
    '') models;
  };
}
