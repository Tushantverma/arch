#!/bin/bash

#part1
##########################################################################
################### checking internet connection #########################
##########################################################################

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


##########################################################################
######################### parallel download ##############################
##########################################################################

sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf


##########################################################################
######################### fixing archlinux keyring #######################
##########################################################################

pacman -Syyyy
# pacman-key --init
# pacman-key --populate
# pacman-key --refresh-keys
pacman --noconfirm -Syyyy archlinux-keyring reflector
reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist

# update your pacman keyring (if you have any issue try billow process one by one)
# pacman -Syyyy
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


##########################################################################
###### setting keyboard layout (optional defaulat is already "us") #######
##########################################################################

loadkeys us

##########################################################################
########################## checking UEFI BOOT only #######################
##########################################################################

if ls /sys/firmware/efi/efivars > /dev/null;
then 
	echo "BOOTED into UEFI all done"
else
	echo "YOU ARE NOT BOOTED INTO UEFI <<<<<<<<====================="
	exit 1
fi

##########################################################################
################## setting/syncing time with network #####################
##########################################################################

timedatectl set-ntp true


##########################################################################
######################## partitioning the disk ###########################
##########################################################################

lsblk
# $fdisk -l (alternetive shows full drive name with /dev/sdaX) 

echo "##### THIS IS BTRFS INSTALL #####"

echo "Enter the drive (/dev/sdaX) : example: "
read drive
cfdisk $drive 

lsblk

echo "Enter the BOOT partition (/dev/sdaX) : "
read bootpartition
mkfs.vfat -F32 $bootpartition

echo "Enter the SWAP partition (/dev/sdaX) : "
read swappartition
mkswap $swappartition
swapon $swappartition

echo "Enter the LINUX partition (/dev/sdaX) : "
read linuxpartition
mkfs.btrfs $linuxpartition
	mount $linuxpartition /mnt
			btrfs su cr /mnt/@
			btrfs su cr /mnt/@home
			btrfs su cr /mnt/@root
			btrfs su cr /mnt/@srv
			btrfs su cr /mnt/@log
			btrfs su cr /mnt/@cache
			btrfs su cr /mnt/@tmp
			btrfs su li /mnt 

			cd /
			umount /mnt 

			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@      $linuxpartition /mnt
			mkdir -p /mnt/{home,root,srv,var/log,var/cache,tmp}

			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@home  $linuxpartition /mnt/home
			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@root  $linuxpartition /mnt/root
			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@srv   $linuxpartition /mnt/srv
			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@log   $linuxpartition /mnt/var/log
			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@cache $linuxpartition /mnt/var/cache
			mount -o defaults,noatime,compress=zstd,commit=120,subvol=@tmp   $linuxpartition /mnt/tmp

	mkdir -p /mnt/boot/efi
	mount $bootpartition /mnt/boot/efi

lsblk


pacstrap /mnt base base-devel linux linux-firmware vim btrfs-progs

genfstab -U /mnt >> /mnt/etc/fstab
#cat /mnt/etc/fstab   (to check fstab is correcto to not)



##########################################################################
########################### chroot into system ###########################
##########################################################################

echo "chrooting into system"
sleep 5s


# create a new script which starts with #part2 and run it in arch-chroot
sed "1,/^#part22$/d" install.sh > /mnt/install2.sh 
chmod +x /mnt/install2.sh
arch-chroot /mnt ./install2.sh

# after running the #part2 unmount /mnt and reboot
umount -R /mnt

echo "installaion DONE auto reboot in 5 second"
sleep 5s
echo "you can REBOOT now"























#part22
##########################################################################
########################### setting up clock #############################
##########################################################################

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

##########################################################################
########################### setting up your local ########################
##########################################################################

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf



##########################################################################
###### setting keyboard layout (optional defaulat is already "us") #######
####################### only do if you did above #########################

echo "KEYMAP=us" > /etc/vconsole.conf


##########################################################################
########################### setting up your HOST #########################
##########################################################################

echo "write HostName/username of the OS: "
read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1       localhost" 						>> /etc/hosts
echo "::1             localhost" 						>> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" 	>> /etc/hosts


##########################################################################
################## setting up Parallel Downloads in chroot ###############
##########################################################################

pacman -Syyyy --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf


##########################################################################
###################### install all needed packages #######################
##########################################################################

pacman -S --noconfirm grub grub-btrfs efibootmgr networkmanager network-manager-applet os-prober bash-completion
# not installing right now ==>  linux-headers-lts linux-lts mtools dialogs dosfstools reflector


### installing graphic packages ######
pacman -S --noconfirm xorg-server xorg-apps xorg-xinit mesa xf86-video-intel intel-ucode



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


##########################################################################
###################### setting up root user password #####################
##########################################################################

echo "set password for root user"
passwd

#username: root
#password:

##########################################################################
###################### setting up GRUB BOOTLOADER ########################
##########################################################################

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

######## booting grub faster
#sed -i 's/quiet/pci=noaer/g' /etc/default/grub
#sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg



##########################################################################
###################### setting up mkinitcpio.conf ########################
##########################################################################

# check this after install

# nano /etc/mkinitcpio.conf
# MODULES=(btrfs)
#		 BINARIES=(btrfs) (NOT USING)
# mkinitcpio -p linux

#sed -i "s/^MODULES=()/MODULES=(btrfs )/" /etc/mkinitcpio.conf
#btrfs crc32c-intel




##########################################################################
########################## createing New USER ############################
##########################################################################

echo "Enter Your Username : "
read username

useradd -m -g users -G audio,video,network,wheel,storage,rfkill -s /bin/bash $username
passwd $username


## adding user into wheel group ##
#echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers  (other option)
#sed -i "s/^#%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
sed -i "s/^#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

#### or ####
#EDITOR=vim visudo
#	%wheel ALL=(ALL:ALL) ALL    (uncomment this line)(ALL)




##########################################################################
########################## starting some deamons #########################
##########################################################################

systemctl enable NetworkManager
#systemctl enable bluetooth			(enable bluetooth)(IDK)
#systemctl enable org.cups.cupsd		(enable printer)(IDK)




##########################################################################
########################## installing display manager ####################
##########################################################################

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


##########################################################################
#############################(( others ))#################################
##########################################################################

# uncomment multilib in /etc/pacman.conf     [multilib] with sed try
# run reflector after install done maybe needed
# check mkinitcpio.conf how to sed and add btrfs module

echo "exiting form chroot"
exit




































