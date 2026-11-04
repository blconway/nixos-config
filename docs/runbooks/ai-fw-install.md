# Clean install of ai-fw

From the NixOS installer USB to a running endpoint, about 30 minutes plus the
model downloads. **This erases the whole disk.**

## Before booting the USB

- BIOS: set the iGPU memory carve-out (UMA frame buffer) to its minimum, so the
  GPU uses GTT, which `boot.kernelParams` in `hosts/ai-fw/default.nix` sizes.
- BIOS: Secure Boot off (systemd-boot here is unsigned).
- Plug in Ethernet.
- Any current NixOS ISO works, minimal is enough: the flake brings its own
  nixpkgs.

## In the installer, as root (`sudo -i`)

1. Find the disk. The commands below assume `/dev/nvme0n1`; change it if
   `lsblk` says otherwise.

   ```sh
   lsblk
   ```

2. Partition: a 1 GiB EFI partition and the rest as root.

   ```sh
   parted -s /dev/nvme0n1 -- mklabel gpt mkpart ESP fat32 1MiB 1GiB set 1 esp on mkpart root ext4 1GiB 100%
   ```

3. Format with the UUIDs already in `hosts/ai-fw/hardware-configuration.nix`,
   so that file stays correct and nothing needs committing mid-install.

   ```sh
   mkfs.fat -F 32 -i 34022528 /dev/nvme0n1p1
   mkfs.ext4 -U 22dddf67-d53a-4ec8-8418-fcdbdfb9d55c /dev/nvme0n1p2
   ```

4. Mount.

   ```sh
   mount /dev/nvme0n1p2 /mnt
   mount --mkdir /dev/nvme0n1p1 /mnt/boot
   ```

5. Install straight from GitHub (the repo is public, D7; no local clone is
   needed, now or later). It asks for a root password at the end; root can't
   log in over SSH, so this is for the console only.

   ```sh
   nixos-install --flake github:blconway/nixos-config#ai-fw --option experimental-features "nix-command flakes"
   ```

6. Give `brandon` a password. The config sets none, and `sudo` needs one.

   ```sh
   nixos-enter --root /mnt -c "passwd brandon"
   ```

7. `reboot`, and remove the USB.

## After first boot

SSH in as `brandon` with your key (password login is off), using the LAN
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

## If it goes wrong

- **No boot entry / drops to UEFI shell:** Secure Boot is still on, or step 5
  failed; boot the USB, repeat steps 4 and 5 (no need to re-format).

What a clean install loses, all of it recreated by the steps above: the
downloaded models (~116 GB, re-downloaded in step 3 after boot), the Tailscale
node identity (a new machine in the admin console; delete the old one), and
SSH host keys (clients will warn once; remove the old `known_hosts` line).
Nothing else on ai-fw holds state.
- **"device not found" for `/` at boot:** a filesystem got a different UUID
  than step 3; check with `blkid` from the USB.
- **GTT total far below 120259084288:** the BIOS carve-out is not at minimum,
  or the kernel parameters didn't apply (`cat /proc/cmdline`).
