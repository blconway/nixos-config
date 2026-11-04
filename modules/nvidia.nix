{ config, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
  };

  # GPU access in Docker and Podman containers through CDI:
  # `docker run --device nvidia.com/gpu=all ...`
  hardware.nvidia-container-toolkit.enable = true;
}
