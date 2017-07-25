#!/bin/bash
arch_chroot() { #{{{
    arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
  }
function mirrors() {
  url="https://www.archlinux.org/mirrorlist/?country=DE&use_mirror_status=on"
  tmpfile=$(mktemp --suffix=-mirrorlist)

  # Get latest mirror list and save to tmpfile
  curl -so ${tmpfile} ${url}
  sed -i 's/^#Server/Server/g' ${tmpfile}

  # Backup and replace current mirrorlist file (if new file is non-zero)
  if [[ -s ${tmpfile} ]]; then
   { echo " Backing up the original mirrorlist..."
     mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig; } &&
   { echo " Rotating the new list into place..."
     mv -i ${tmpfile} /etc/pacman.d/mirrorlist; }
  else
    echo " Unable to update, could not download list."
  fi
  # better repo should go first
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
  rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
  rm /etc/pacman.d/mirrorlist.tmp
  # allow global read access (required for non-root yaourt execution)
  chmod +r /etc/pacman.d/mirrorlist
  #TODO: ask if should open editor
  $EDITOR /etc/pacman.d/mirrorlist
}
function createdrive() {
  cfdisk
  partition=/dev/sda1
  mkfs.btrfs -L "Arch Linux" $partition

  mkdir /mnt/btrfs-root
  mount -o defaults,relatime,discard,ssd,nodev,nosuid $partition /mnt/btrfs-root

  mkdir -p /mnt/btrfs-root/__snapshot
  mkdir -p /mnt/btrfs-root/__current
  btrfs subvolume create /mnt/btrfs-root/__current/root
  btrfs subvolume create /mnt/btrfs-root/__current/home

  mkdir -p /mnt/btrfs-current
  mount -o defaults,relatime,discard,ssd,nodev,subvol=__current/root $partition /mnt/btrfs-current
  mkdir -p /mnt/btrfs-current/home

  mount -o defaults,relatime,discard,ssd,nodev,nosuid,subvol=__current/home $partition /mnt/btrfs-current/home
}
function baseinstall() {
  mountpoint=/mnt/btrfs-current
  pacstrap $mountpoint base base-devel parted btrfs-progs f2fs-tools ntp net-tools
  WIRED_DEV=`ip link | grep "ens\|eno\|enp" | awk '{print $2}'| sed 's/://' | sed '1!d'`
   if [[ -n $WIRED_DEV ]]; then
     arch_chroot "systemctl enable dhcpcd@${WIRED_DEV}.service"
   fi
   echo "KEYMAP=US" > $mountpoint/etc/vconsole.conf
   #genfstab -L -p mountpoint >> mountpoint/etc/fstab
   genfstab -U /mnt >> $mountpoint/etc/fstab

}
function configsystem() {
  arch-chroot /mnt/btrfs-current
  ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
  #hwclock --systohc
  $EDITOR /etc/locale.gen
  locale-gen
  $EDITOR /etc/locale.conf
  $EDITOR /etc/vconsole.conf
  echo "wArch" > $mountpoint/etc/hostname
  echo "Root password"
  passwd
  umount -R /mnt
}
export EDITOR=vim
timedatectl set-ntp true
mirros
createdrive
baseinstall
