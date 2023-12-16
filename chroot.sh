#!/usr/bin/env bash

# run the whole script as root 
[ "$EUID" -ne 0 ] && echo "This script requires root privileges." && exec sudo sh "$0" "$@"; 


################### if file system is already mounted then umount it #########################
if mountpoint -q "/mnt"; then
  umount -lf "/mnt" && echo "Successfully unmounted the filesystem." || (echo "Failed to unmount the filesystem. Exiting." && exit 1)
else
  echo "File system is not mounted already."
fi


lsblk -p  ## -p => prints full device path
read -rep "$(tput setaf 2)Enter the LINUX partition (e.g. /dev/sdaX) : $(tput sgr0)"  linuxpartition 



######################### copied from my arch installation script ##############################
############ this mount and arch installation script mount both should be same #################

 mountpoint="defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120"
 mount -o "$mountpoint",subvol=@             $linuxpartition /mnt
 mkdir -p /mnt/{home,root,srv,var/{log,cache/pacman/pkg},tmp,.snapshots}

# I'm setting options manually otherwise it will set some options automatically (this will reflect in /etc/fstab)
 mount -o "$mountpoint",subvol=@home         $linuxpartition /mnt/home
#mount -o "$mountpoint",subvol=@root         $linuxpartition /mnt/root
 mount -o "$mountpoint",subvol=@srv          $linuxpartition /mnt/srv
 mount -o "$mountpoint",subvol=@tmp          $linuxpartition /mnt/tmp
#mount -o "$mountpoint",subvol=@.snapshots   $linuxpartition /mnt/.snapshots

# fixing. pkg rollback fully & properly after snapshot restore ## now you can reinstall same package after restoring the snapshot #timeshift fixed
 mount -o "$mountpoint",subvol=@var_log      $linuxpartition /mnt/var/log
 mount -o "$mountpoint",subvol=@var_pkg      $linuxpartition /mnt/var/cache/pacman/pkg
################################################################################################


echo "###################################################################################"
echo "############ chrooting into system #### su <username> to switch user ##############"
echo "#### you can access your system files at /mnt now.. without arch-chroot as well ###"
echo "###################################################################################"

arch-chroot /mnt

