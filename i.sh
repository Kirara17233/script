#!/usr/bin/zsh

run() {
  errpath="/mnt/err.info"
  if [ $2 ]; then
    errpath=$2
  fi
  echo "$1 2>> $errpath" | zsh
  if [ "$?" -ne 0 ]; then
    run $1 $errpath
  fi
}

rm err.info

# Update the system clock
run "timedatectl set-ntp true" err.info

# Partition the disks
run "sed -e \"s| *#.*||g\" << EOF | fdisk /dev/sda
g     # create a new empty GPT(GUID) partition table
n     # add a new partition as EFI system
      # default partition number: 1
      # default starting sector
+512M # +512M as ending sector
t     # change the partition type
1     # EFI System
n     # add a new partition
      # default partition number: 2
      # default starting sector
      # ending sector(all the remaining space)
w     # write table to disk and exit
EOF" err.info

# Format the partitions
run "mkfs.fat -F32 /dev/sda1" err.info
run "mkfs.ext4 /dev/sda2" err.info

# Mount the file systems
run "mount /dev/sda2 /mnt" err.info
run "mkdir /mnt/boot" err.info
run "mount /dev/sda1 /mnt/boot" err.info

# save err.info
run "cp err.info /mnt/err.info" err.info

# Install basic packages
run "pacstrap /mnt base base-devel linux linux-firmware dhcpcd openssh neovim sudo zsh git neofetch"

# Change the default shell to zsh
run "rm /mnt/etc/skel/.bash*"
run "sed -i \"s|/bin/bash|/usr/bin/zsh|g\" /mnt/etc/default/useradd /mnt/etc/passwd"

# Configure the system
run "genfstab -U /mnt >> /mnt/etc/fstab"

# Get chroot.sh
run "curl -o /mnt/chroot.sh https://raw.githubusercontent.com/Kirara17233/script/main/chroot.sh"
run "chmod +x /mnt/chroot.sh"

# Chroot
run "arch-chroot /mnt /step1.sh $1 $2 $3 $4 $5 $6"

# 重启
run "umount /mnt/boot"
run "umount /mnt"
reboot
