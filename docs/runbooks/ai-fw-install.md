# Clean install of ai-fw

Boot the ai-fw installer USB, then run one command over SSH from bc-ws. About
20 minutes plus the model downloads. **This erases the whole disk.**

## Before booting the USB

- Build the ISO and write it to a USB stick, from any machine with Nix:

  ```sh
  nix build github:blconway/nixos-config#ai-fw-installer-iso
  sudo dd if=result/iso/ai-fw-installer-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
  ```

  (`/dev/sdX` is the USB stick; check with `lsblk`. On Windows, write the
  `.iso` with Rufus or balenaEtcher instead.)
- BIOS: set the iGPU memory carve-out (UMA frame buffer) to its minimum, so the
  GPU uses GTT, which `boot.kernelParams` in `hosts/ai-fw/default.nix` sizes.
- BIOS: Secure Boot off (systemd-boot here is unsigned).
- Plug in Ethernet.

## Install

1. Boot the USB. At the installer's prompt, `ip -4 addr` shows its address.
2. Either at the installer's own console:

   ```sh
   sudo install-ai-fw /dev/nvme0n1
   ```

   or over SSH from a machine holding one of ai-fw's keys (the ones at
   github.com/blconway.keys):

   ```sh
   ssh -t root@<installer-address> install-ai-fw /dev/nvme0n1
   ```

   It shows the disk, asks you to type its name to confirm, asks for
   `brandon`'s password (used for `sudo`; ai-fw's root has none, D12), then
   partitions, formats with the UUIDs in `hosts/ai-fw/hardware-configuration.nix`
   and installs `github:blconway/nixos-config#ai-fw`. Check the disk name with
   `lsblk` if the box has more than one.
3. Remove the USB and reboot.

`hosts/ai-fw-installer/install-ai-fw.sh` is the procedure; to install from a
stock NixOS ISO instead, run its steps by hand.

## After first boot

Log in as `brandon`: at the console with the password you set, or over SSH
with one of ai-fw's keys (password login over SSH is off), using the LAN
address until Tailscale is up.

1. Join the tailnet, then approve the machine in the Tailscale admin console:
   `sudo tailscale up`
2. Check the result:
   - `hostname` prints `ai-fw`
   - `cat /sys/class/drm/card*/device/mem_info_gtt_total` prints `120259084288` (112 GiB)
   - `systemctl status llama-cpp` is active
   - `systemctl list-timers nixos-upgrade` shows the next run at 04:10
3. The models download by themselves: `llama-cpp-warmup` starts at boot and
   fetches both (~116 GB), then asks each one "hi". Follow it, and expect it
   to finish as `inactive (dead)` with `status=0/SUCCESS`:

   ```sh
   journalctl -fu llama-cpp-warmup
   systemctl status llama-cpp-warmup
   ```

4. From another tailnet device: `curl http://ai-fw:8080/v1/models`.
5. Check the performance settings took effect (D13):
   - `journalctl -b -u platform-profile-performance` ends with
     `platform_profile: performance`
   - `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` prints `performance`
6. Measure what D13 left open, once the models are downloaded. The files are
   under `/var/cache/private/llama-cpp` (`sudo find` them), for example:

   ```sh
   sudo llama-bench -m <qwen3.8 file> -fa on -lm none,mmap -ub 512,1024 -p 512,16384 -n 128
   ```

   Then try Flash-Next with its MTP draft in a real agent task, and record the
   numbers in D13 before changing a default.

What a clean install loses, all of it recreated by the steps above: the
downloaded models (~116 GB, re-downloaded after boot), the Tailscale node
identity (a new machine in the admin console; delete the old one), and SSH
host keys (clients will warn once; remove the old `known_hosts` line).
Nothing else on ai-fw holds state.

## If it goes wrong

- **`ssh` to the installer is refused:** the key you're using isn't one of
  ai-fw's (`hosts/ai-fw/default.nix`); the installer accepts only those.
- **No boot entry / drops to UEFI shell:** Secure Boot is still on, or the
  install failed; boot the USB and run `install-ai-fw` again.
- **"device not found" for `/` at boot:** a filesystem got a different UUID
  than `hardware-configuration.nix` expects; check with `blkid` from the USB.
- **GTT total far below 120259084288:** the BIOS carve-out is not at minimum,
  or the kernel parameters didn't apply (`cat /proc/cmdline`).
- **Forgot `brandon`'s password:** boot the USB, then
  `mount /dev/nvme0n1p2 /mnt && nixos-enter --root /mnt -c "passwd brandon"`.
