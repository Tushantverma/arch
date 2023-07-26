#!/bin/bash

#setfont ter-128n   #### changing the font size "ter" is a font name and "128n" is the font size
#screen -h 99999    #### for scrollback on tty while installing OS (99999 is the schrollback buffer) (it's tmux alternative ) eanble scrolling "ctrl + a ["     disable scrolling "esc"

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

lsblk -p  ## -p => prints full device path
# $fdisk -l (alternetive shows full drive name with /dev/sdaX) 

echo "#################################"
echo "##### THIS IS BTRFS INSTALL #####"
echo "##### YOU DON'T NEED TO DELETE AND RECREATE PARTITION IF IT'S ALREADY THERE JUST ENTER IN CFDISK CHECK EVERYTHING THEN QUIT #####"

echo "Enter the drive (/dev/sda) : "
read drive
cfdisk $drive 

sleep 5s
lsblk -p  ## -p => prints full device path

######## how to wipe your file signature/ complete wipe your disk or partition ############
# wipefs -a /dev/sda  ###(to wipe only all file signature) faster method ===>recommended 
# wipefs -t ext4 /dev/sda  ###(to wipe only specific file signature only not all file signature) faster method (never tried)
# dd if=/dev/zero of=/dev/sda bs=1M  ###(to complete wipe full file system or full partition by adding random data 1 time)
# shred -vfz /dev/sda ###(to complete wipe full file system or full partition by adding random data 4 time) (most secure way. time taking) not good for ssd life

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

sleep 10s #check all correct above
	mount $linuxpartition /mnt
	
	btrfs su cr /mnt/@
	btrfs su cr /mnt/@home
#	btrfs su cr /mnt/@root
	btrfs su cr /mnt/@srv
	btrfs su cr /mnt/@var_log
	btrfs su cr /mnt/@var_pkg
	btrfs su cr /mnt/@tmp
	btrfs su cr /mnt/@.snapshots
	btrfs su li /mnt 

	umount /mnt 

	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@      	$linuxpartition /mnt
	mkdir -p /mnt/{home,srv,var/{log,cache/pacman/pkg},tmp,.snapshots} #/mnt/root

	# I'm setting options manually otherwise it will set some options automatically (this will reflect in /etc/fstab)
	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@home  	$linuxpartition /mnt/home
#	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@root  	$linuxpartition /mnt/root
	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@srv   	$linuxpartition /mnt/srv

	# fixing. pkg rollback fully & properly after snapshot restore ## now you can reinstall same package after restoring the snapshot #timeshift fixed
	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@var_log   	$linuxpartition /mnt/var/log
	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@var_pkg   	$linuxpartition /mnt/var/cache/pacman/pkg

	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@tmp   	$linuxpartition /mnt/tmp
	mount -o defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120,subvol=@.snapshots   $linuxpartition /mnt/.snapshots
	##### others option you can use above #####
	# ssd, ==> if you are using the ssd
	#
	# compress=zstd (auto select compression level) (automatically and recommended) <<<=====================
	# compress=zstd:3 (good for HDD)(compress almost all files expect some)(low compression faster R/W speed) 
	# compress-force=zstd:15 (good for SSD)(compress all files forcefully)(high compression low R/W speed)
	## if you are storing mp3,mp4,zip it's better to use low or no compression because files are already compressed
	## you can use any number of compression b/w 1 to 15 
	#
	# discard=async,space_cache=v2, ==>>> if you dont add this option it will automatically be added in /etc/fstab
	# autodefrag ===>> will automatically defrag your btrfs file system :)
	# @var ===>> this subvolume is fixing timeshift snapshots not deleting error :)
	

	# fixing timeshift snapshot not deleting error | will maybe break systemd-nspawn but docker is a good alternative
	# btrfs subvolume delete /mnt/var/lib/{machines,portables}
	mkdir -p /mnt/var/lib/{machines,portables} # creating regular directory at there place    #timeshift fixed



	mkdir -p /mnt/boot/efi
	mount $bootpartition /mnt/boot/efi



lsblk -p  ## -p => prints full device path
sleep 5s


### what kernal do you want to use
# what ever the linux kernal you are using here you also need to change it in linux-headers if you are using it
# linux
# linux-hardened
# linux-lts
# linux-zen

pacstrap /mnt base base-devel linux-zen linux-firmware neovim btrfs-progs
   
genfstab -U -p /mnt >> /mnt/etc/fstab
# The -p flag include all the partitions including those that are not currently mounted... -U flags tells use UUID in fstab
#cat /mnt/etc/fstab   (to check fstab is correcto to not)
sed -i 's#subvolid=[[:digit:]]\+,##g' /mnt/etc/fstab     ### fixing automatically subvolume mount when restoring the snapshots by removing subvolid=256(or any number) #timeshift fixed ## you can remove "subvolid" because "subvol" is already there otherwise both would be in conflict


echo "##########################################################################"
echo "########################### chroot into system ###########################"
echo "##########################################################################"

echo "chrooting into system"
sleep 5s


# create a new script which starts with #part2 
# runing the #part2 of script in arch-chroot
# sed "1,/^#part22$/d" ~/arch/install.sh > /mnt/install2.sh 

# ${0} means script full path with name which script is executing | where `basename $0` means just script name without path
sed "1,/^#part22$/d" ${0} > /mnt/install2.sh 
chmod +x /mnt/install2.sh
arch-chroot /mnt ./install2.sh

# after running the #part2 unmount /mnt and reboot
echo "unmount /mnt && exit script && removeing /mnt/install2.sh in 10 second"
echo "you can use ## 'arch-chroot /mnt'  now "
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

echo "write HostName/NickName for the OS(tv): "
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

pacman -S --noconfirm git
git clone --depth 1 https://github.com/arcolinux/arcolinux-spices.git
./arcolinux-spices/usr/share/arcolinux-spices/scripts/get-the-keys-and-repos.sh
pacman -Syyy
rm -rf arcolinux-spices
# source :- https://www.arcolinux.info/arcolinux-spices-application/





echo "##########################################################################"
echo "###################### install all needed packages #######################"
echo "##########################################################################"

pkgs=(

############### Display pkg ################
xorg-server
xorg-apps
xorg-xinit
mesa
intel-ucode
# xf86-video-intel ## not installing this pkg because its changing display name, giving error for other pkg (eg. vibrent-linux)

grub
grub-btrfs
efibootmgr
networkmanager
network-manager-applet
os-prober
bash-completion

gparted
dosfstools    # required by gparted
mtools	      # required by gparted

bat
htop
neofetch
sublime-text-4
yay
thunar
gvfs
gvfs-afc
thunar-volman
tumbler
ffmpegthumbnailer
thunar-archive-plugin
thunar-media-tags-plugin
pavucontrol
mpv
pulseaudio
pulseaudio-alsa
ntfs-3g
feh
xfce4-terminal
sxhkd
rofi

### fonts ###
ttf-iosevka-nerd
ttf-indic-otf
noto-fonts

polkit-gnome
man-db
fzf
xclip
chezmoi
tree
tldr
light
alsa-utils
net-tools
wireless_tools
file-roller
yt-dlp
meld
catfish

#### themes ####
lxappearance
qt5ct
a-candy-beauty-icon-theme-git
sweet-cursor-theme-git
sweet-gtk-theme-dark
xcursor-breeze
arc-blackest-theme-git

# linux-headers-lts
# linux-lts
# dialogs
# reflector

)

pacman -S --noconfirm --needed "${pkgs[@]}"



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
# BINARIES=(btrfs) (NOT USING)

# mkinitcpio -p linux-zen ## genrate the default config for mkinitcpio  (this is kernal name)
# mkinitcpio -P           ## re-genrate the config for mkinitcpio

sed -i "s/MODULES=()/MODULES=(btrfs)/" /etc/mkinitcpio.conf
mkinitcpio -P

#btrfs crc32c-intel




echo "##########################################################################"
echo "########################## creating New USER ############################"
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
#EDITOR=nvim visudo    #### and you should not use "#EDITOR=neovim visudo"
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
echo "################# setting up touchpad configuration ######################"
echo "##########################################################################"

echo '
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"                # apply config only on touchpad
    Option "Tapping" "on"               # enable tap
    Option "ClickMethod" "clickfinger2" # double tap == right click
    Option "NaturalScrolling" "on"
    Option "DisableWhileTyping" "true"
EndSection ' > /etc/X11/xorg.conf.d/30-touchpad.conf



echo "##########################################################################"
echo "##################### installing display manager #########################"
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
echo "####################### searching for virtualization #####################"
echo "##########################################################################"

hypervisor=$(systemd-detect-virt)
    case $hypervisor in
    	none )      echo "main machine is detected"
		            pacman --noconfirm -S picom 
                    ;;
        kvm )  	    echo "KVM has been detected, setting up guest tools."
               	    #pacstrap /mnt qemu-guest-agent &>/dev/null
                    #systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
              	    ;;
        vmware  )   echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
                    #pacstrap /mnt open-vm-tools >/dev/null
                    #systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    #systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    echo "VirtualBox has been detected, setting up guest tools."
                    pacman --noconfirm -S virtualbox-guest-utils 
                    systemctl enable vboxservice.service
                    ;;
        microsoft ) echo "Hyper-V has been detected, setting up guest tools."
                    #pacstrap /mnt hyperv &>/dev/null
                    #systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    #systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    #systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
    esac




echo " part2 is DONE here "





echo "##########################################################################"
echo "########################## setting up my config ##########################"
echo "##########################################################################"


#part33

su - $username -c "chezmoi init --apply https://github.com/tushantverma/dotfiles"
./home/$username/.myscripts/1_setup_all.sh














