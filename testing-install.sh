#!/bin/bash

#setfont ter-128n   #### changing the font size "ter" is a font name and "128n" is the font size
#part11
echo "##########################################################################"
echo "################### checking internet connection #########################"
echo "##########################################################################"

# if ping -c 4 google.com > /dev/null;
# then 
# 	 echo "Connected to the internet all done"
# else
#	 echo "No internet connection read comment"
#	 echo "use iwctl to connect... ex: station wlan0 connect 'ESSID'"
#	 exit 1
# fi

# how to install arch linux
# connect to the wifi network
#	$ iwctl
#	> device list (show device list)
#	> station wlan0 scan (to scan wifi near me)
#	> station wlan0 get-network (to show all network)
#	> station wlan0 connect "ESSID" (you can directlly connect it by this)
#		passphrase: *****
# exit and check $ping -c 4 google.com


echo "##########################################################################"
echo "######################### parallel download ##############################"
echo "##########################################################################"

sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf


echo "##########################################################################"
echo "######################### fixing archlinux keyring #######################"
echo "##########################################################################"


pacman --noconfirm -Syyy archlinux-keyring reflector
reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist

# update your pacman keyring (if you have any issue try billow process one by one)
# pacman -Syyy
# pacman-key --init
# pacman-key --populate
# pacman-key --refresh-keys
# pacman -S archlinux-keyring
# pacman -S reflector
# 	  mirror='sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
# 	  mirrora='sudo reflector --latest 30 --number 10 --sort age --save /etc/pacman.d/mirrorlist'
# 	  mirrord='sudo reflector --latest 30 --number 10 --sort delay --save /etc/pacman.d/mirrorlist'
# 	  mirrors='sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist'
# 	  mirrorx='sudo reflector --age 6 --latest 20  --fastest 20 --threads 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist'
# reboot your system if problem is not fixed


echo "##########################################################################"
echo "###### setting keyboard layout (optional defaulat is already 'us') #######"
echo "##########################################################################"

loadkeys us

echo "##########################################################################"
echo "########################## checking UEFI BOOT only #######################"
echo "##########################################################################"

if ls /sys/firmware/efi/efivars > /dev/null;
then 
	echo "BOOTED into UEFI all done"
else
	echo "YOU ARE NOT BOOTED INTO UEFI <<<<<<<<====================="
	exit 1
fi


echo "##########################################################################"
echo "################## setting/syncing time with network #####################"
echo "##########################################################################"

timedatectl set-ntp true



echo "##########################################################################"
echo "######################## partitioning the disk ###########################"
echo "##########################################################################"

lsblk
# $fdisk -l (alternetive shows full drive name with /dev/sdaX) 

echo "#################################"
echo "##### THIS IS BTRFS INSTALL #####"
echo "##### YOU DON'T NEED TO DELETE AND RECREATE PARTITION IF IT'S ALREADY THERE JUST ENTER IN CFDISK CHECK EVERYTHING THEN QUIT #####"

echo "Enter the drive (/dev/sda) : "
read drive
cfdisk $drive 

lsblk






echo "Enter the BOOT partition (/dev/sdaX) : "
read bootpartition
wipefs -af $bootpartition  # wipe boot file signature forcefully
mkfs.vfat -F32 $bootpartition 

echo "Enter the SWAP partition (/dev/sdaX) : "
read swappartition
wipefs -af $swappartition # wipe swap file signature forcefully
mkswap $swappartition -f    ###-f = forcefully if any error there
swapon $swappartition

echo "Enter the LINUX partition (/dev/sdaX) : "
read linuxpartition
wipefs -af $linuxpartition  # wipe linux file signature forcefully 
mkfs.btrfs $linuxpartition -f   ###-f = forcefully if any error there



########################################################################################################################################





sleep 10s #check all correct above
	mount $linuxpartition /mnt
	


		btrfs su cr /mnt/@ 
		btrfs su cr /mnt/@/.snapshots 
		btrfs su cr /mnt/@/home 
		btrfs su cr /mnt/@/root 
		btrfs su cr /mnt/@/srv 
		btrfs su cr /mnt/@/var_log 
		btrfs su cr /mnt/@/var_cache 
		btrfs su cr /mnt/@/var_tmp 
		 

		umount /mnt

mount -o noatime,space_cache=v2,compress=zstd,subvol=@/  $linuxpartition /mnt

mkdir -p /mnt/{root,home,.snapshots,srv,/var/log,/var/cache,/var/tmp}

mount -o noatime,space_cache=v2,autodefrag,compress=zstd,discard=async,nodev,nosuid,subvol=@/root $linuxpartition /mnt/root
mount -o noatime,space_cache=v2,autodefrag,compress=zstd,discard=async,nodev,nosuid,subvol=@/home $linuxpartition /mnt/home
mount -o noatime,space_cache=v2,autodefrag,compress=zstd,discard=async,subvol=@/.snapshots $linuxpartition /mnt/.snapshots
mount -o noatime,space_cache=v2.autodefrag,compress=zstd,discard=async,subvol=@/srv $linuxpartition /mnt/srv
mount -o noatime,space_cache=v2,autodefrag,compress=zstd,discard=async,nodatacow,nodev,nosuid,noexec,subvol=@/var_log $linuxpartition /mnt/var/log
mount -o noatime,space_cache=v2,autodefrag,compress=zstd,discard=async,nodatacow,nodev,nosuid,noexec,subvol=@/var_cache $linuxpartition /mnt/var/cache
mount -o noatime,space_cache=v2,autodefrag,compress=zstd,discard=async,nodatacow,nodev,nosuid,subvol=@/var_tmp $linuxpartition /mnt/var/tmp








########################################################################################################################################







	mkdir -p /mnt/boot/efi
	mount $bootpartition /mnt/boot/efi



lsblk
sleep 5s


pacstrap /mnt base base-devel linux-zen linux-firmware vim btrfs-progs
   
genfstab -U -p /mnt >> /mnt/etc/fstab
# The -p flag include all the partitions including those that are not currently mounted... -U flags tells use UUID in fstab
#cat /mnt/etc/fstab   (to check fstab is correcto to not)
sed -i 's#subvolid=[[:digit:]]\+,##g' /mnt/etc/fstab     ### fixing automatically subvolume mount when restoring the snapshots by removing subvolid=256(or any number)


echo "##########################################################################"
echo "########################### chroot into system ###########################"
echo "##########################################################################"

echo "chrooting into system"
sleep 5s


# create a new script which starts with #part2 
# runing the #part2 of script in arch-chroot
sed "1,/^#part22$/d" ~/arch/testing-install.sh > /mnt/install2.sh 
chmod +x /mnt/install2.sh
arch-chroot /mnt ./install2.sh

# after running the #part2 unmount /mnt and reboot
echo "unmount /mnt && exit script && removeing /mnt/install2.sh in 10 second"
sleep 10s
rm -rf /mnt/install2.sh
umount -R /mnt

echo "installaion DONE you can reboot now"
exit























#part22

echo "##########################################################################"
echo "########################### setting up clock #############################"
echo "##########################################################################"

# setup your timezone
# file is already in your system you just need to link it with other location

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
#					       <TAB> / <TAB>
#---------------------or------------------------------
#timedatectl list-timezones  (to check all the timezone)
#timedatectl set-timezone Asia/Kalkata
#							 /Calcutta (maybe)

# sync hardware clock
hwclock --systohc


echo "##########################################################################"
echo "########################### setting up your local ########################"
echo "##########################################################################"

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf



echo "##########################################################################"
echo "###### setting keyboard layout (optional defaulat is already 'us') #######"
echo "####################### only do if you did above #########################"

echo "KEYMAP=us" > /etc/vconsole.conf


echo "##########################################################################"
echo "########################### setting up your HOST #########################"
echo "##########################################################################"

echo "write HostName/username of the OS(tv): "
read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts


echo "##########################################################################"
echo "################## setting up Parallel Downloads in chroot ###############"
echo "##########################################################################"

pacman -Syyy --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf


echo "##########################################################################"
echo "###################### install all needed packages #######################"
echo "##########################################################################"

pacman -S --noconfirm grub grub-btrfs efibootmgr networkmanager network-manager-applet os-prober bash-completion git dosfstools mtools
# not installing right now ==>  linux-headers-lts linux-lts mtools dialogs dosfstools reflector
# dosfstools mtools ===>>> is required by gparted

### installing graphic packages ######
pacman -S --noconfirm xorg-server xorg-apps xorg-xinit mesa intel-ucode
## xf86-video-intel ## not installing this pkg because its changing display name error for other pkg (eg. vibrent-linux)


### my packages
pacman -S --noconfirm bat htop neofetch


#### bugs pkg ####
# pacman -S --noconfirm xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
#      noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome \
#      sxiv mpv zathura zathura-pdf-mupdf ffmpeg imagemagick  \
#      fzf man-db xwallpaper python-pywal unclutter xclip maim \
#      zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl  \
#      dosfstools ntfs-3g git sxhkd zsh pipewire pipewire-pulse \
#      emacs-nox arc-gtk-theme rsync qutebrowser dash \
#      xcompmgr libnotify dunst slock jq aria2 cowsay \
#      dhcpcd connman wpa_supplicant rsync pamixer mpd ncmpcpp \
#      zsh-syntax-highlighting xdg-user-dirs libconfig \
#      bluez bluez-utils


echo "##########################################################################"
echo "###################### setting up root user password #####################"
echo "##########################################################################"

echo "set password for root user"
passwd

#username: root
#password:

echo "##########################################################################"
echo "###################### setting up GRUB BOOTLOADER ########################"
echo "##########################################################################"

grub-install --target=x86_64-efi --efi-directory=/boot/efi
#(--bootloader-id=arch ) default bootloader id is already "arch" only add --bootloader-id=XYZ if you want to change default
#grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

######## booting grub faster
#sed -i 's/quiet/pci=noaer/g' /etc/default/grub
#sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub

# this will show the entry of other OS on grub if you are using dual boot windows will show in the grub (must needed) <<<======
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

# this is also known as "update-grub" command in other distribution you can make alias of this
grub-mkconfig -o /boot/grub/grub.cfg


# to fix the configuration of grub (must needed) <<<<<=======================================
mkdir /boot/efi/EFI/boot
cp /boot/efi/EFI/arch/grubx64.efi /boot/efi/EFI/boot/bootx64.efi




echo "##########################################################################"
echo "###################### setting up mkinitcpio.conf ########################"
echo "##########################################################################"

# check this after install

# nano /etc/mkinitcpio.conf
# MODULES=(btrfs)
#		 BINARIES=(btrfs) (NOT USING)
# mkinitcpio -p linux

sed -i "s/MODULES=()/MODULES=(btrfs)/" /etc/mkinitcpio.conf
mkinitcpio -p linux-zen

#btrfs crc32c-intel




echo "##########################################################################"
echo "########################## createing New USER ############################"
echo "##########################################################################"

echo "Enter Your Username : "
read username

useradd -m -g users -G audio,video,network,wheel,storage,rfkill -s /bin/bash $username
passwd $username


## adding user into wheel group ##
#echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers  (other option)
#echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers 
#sed -i "s/^#%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

#### or ####
#EDITOR=vim visudo
#	%wheel ALL=(ALL:ALL) ALL    (uncomment this line)(ALL)




echo "##########################################################################"
echo "########################## starting some deamons #########################"
echo "##########################################################################"

systemctl enable NetworkManager
#systemctl enable bluetooth			(enable bluetooth)(IDK)
#systemctl enable org.cups.cupsd		(enable printer)(IDK)




echo "##########################################################################"
echo "############### setting up auto temporary file cleanup ###################"
echo "##########################################################################"

echo "
## always enable /tmp directory cleaning (deleting /tmp files after every boot)
D! /tmp 1777 root root 0

## remove files in /var/tmp older than 2 days
D /var/tmp 1777 root root 2d

## namespace mountpoints (PrivateTmp=yes) are excluded from removal
x /tmp/systemd-private-*
x /var/tmp/systemd-private-*
X /tmp/systemd-private-*/tmp
X /var/tmp/systemd-private-*/tmp" > /etc/tmpfiles.d/tmp.conf




echo "##########################################################################"
echo "########################## installing display manager ####################"
echo "##########################################################################"

# $startx (how to use) or $startx awesome
	#   .xinitrc {
	# 	exec wm
	# 	or 
	# 	exec <path to wm>
	# }


### install lightdm
# sudo pacman -S lightdm
# sudo pacman -S lightdm-gtk-greeter lightdm-gtk-greeter-settings
# sudo systemctl enable lightdm.service


### install sddm
# sudo pacman -S sddm
# sudo systemctl enable sddm.service



echo "##########################################################################"
echo "#############################(( others ))#################################"
echo "##########################################################################"

# uncomment multilib in /etc/pacman.conf     [multilib] with sed try

echo " "                                    >> /etc/pacman.conf
echo "[multilib]"                           >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist"   >> /etc/pacman.conf
pacman -Syyy


# reflector now needed after install it will get mirrorlist form live install to main system
# check mkinitcpio.conf how to sed and add btrfs module




echo "##########################################################################"
echo "######################## getting arco key and repo #######################"
echo "##########################################################################"

git clone --depth 1 https://github.com/arcolinux/arcolinux-spices.git
./arcolinux-spices/usr/share/arcolinux-spices/scripts/get-the-keys-and-repos.sh
pacman -Syyy
rm -rf arcolinux-spices
# source :- https://www.arcolinux.info/arcolinux-spices-application/


pacman -S --noconfirm sublime-text-4 yay thunar gvfs gvfs-afc thunar-volman tumbler ffmpegthumbnailer thunar-archive-plugin thunar-media-tags-plugin pavucontrol gparted mpv pulseaudio pulseaudio-alsa ntfs-3g feh alacritty sxhkd rofi ttf-iosevka-nerd polkit-gnome xfce4-power-manager man-db

echo "part2 is DONE here"





































