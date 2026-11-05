# install-ai-fw <disk>: erase <disk> and install ai-fw from GitHub.
# ROOT_UUID, BOOT_ID, BOOT_OPTS and FLAKE are set above this line from ai-fw's own config
# (hosts/ai-fw-installer/default.nix), so the new filesystems match
# hosts/ai-fw/hardware-configuration.nix.

die() {
  echo "install-ai-fw: $*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || die "run as root"
disk=${1:-}
[ -n "$disk" ] || die "usage: install-ai-fw /dev/nvme0n1 [flake]"
# A second argument installs another flake, e.g. a branch before it merges:
# github:blconway/nixos-config/<branch>#ai-fw
FLAKE=${2:-$FLAKE}
[ -b "$disk" ] || die "$disk is not a block device"

case "$disk" in
  *nvme* | *mmcblk*) part="${disk}p" ;;
  *) part="$disk" ;;
esac

lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS "$disk"
echo
read -r -p "Everything on $disk will be erased. Type $disk to continue: " answer
[ "$answer" = "$disk" ] || die "not confirmed, nothing changed"

read -r -s -p "Password for brandon (used for sudo): " pw1
echo
read -r -s -p "Again: " pw2
echo
[ -n "$pw1" ] || die "empty password"
[ "$pw1" = "$pw2" ] || die "passwords differ"

echo "== partitioning $disk"
umount -R /mnt 2>/dev/null || true
wipefs -a "$disk"
parted -s "$disk" -- mklabel gpt \
  mkpart ESP fat32 1MiB 1GiB set 1 esp on \
  mkpart root ext4 1GiB 100%
udevadm settle

echo "== formatting with ai-fw's UUIDs"
mkfs.fat -F 32 -i "$BOOT_ID" "${part}1"
mkfs.ext4 -F -U "$ROOT_UUID" "${part}2"
udevadm settle
[ -e "/dev/disk/by-uuid/$ROOT_UUID" ] || die "root filesystem did not get UUID $ROOT_UUID"

echo "== mounting"
mount "${part}2" /mnt
mount --mkdir -o "$BOOT_OPTS" "${part}1" /mnt/boot

echo "== installing $FLAKE"
nixos-install --no-root-passwd --no-channel-copy --flake "$FLAKE"

echo "== setting brandon's password"
printf 'brandon:%s\n' "$pw1" | nixos-enter --root /mnt -c chpasswd

umount -R /mnt
echo
echo "ai-fw is installed. Remove the USB stick and reboot. Then follow"
echo "docs/runbooks/ai-fw-install.md, \"After first boot\"."
