#!/usr/bin/env bash

# setfont ter-128n   #### changing the font size "ter" is a font name and "128n" or "v28n" is the font size example
# screen -h 99999    #### for scrollback on tty while installing OS (99999 is the schrollback buffer) (it's tmux alternative ) eanble scrolling "ctrl + a ["     disable scrolling "esc"

# bash <(curl -L https://raw.githubusercontent.com/Tushantverma/arch/main/testing-install.sh)          ## you can run the script this way without git clone  (my script is not designed to use this... #not working)
# curl -o install.sh -L https://raw.githubusercontent.com/Tushantverma/arch/main/testing-install.sh    ## you can get the script this way without git clone


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
echo "############### setting up /etc/pacman.conf (for live ISO) ###############"
echo "##########################################################################"


setup_pacman_conf() {

	sed -i 's/#Color/Color/'                                                     /etc/pacman.conf   # enable color for pacman
	sed -i 's/#VerbosePkgLists/VerbosePkgLists/'                                 /etc/pacman.conf   # show difference b/w old and new packages version
	sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 15/'                  /etc/pacman.conf   # enable parallel downloads
	sed -i '/^ParallelDownloads = [0-9]\+$/a ILoveCandy\nDisableDownloadTimeout' /etc/pacman.conf   # added ILoveCandy and (DisableDownloadTimeout for slow internet) after Parallel Downloads line
	sed -i '/\[multilib\]/,/Include/''s/^#//'                                    /etc/pacman.conf   # uncomment multilib repo
	# source https://github.com/arcolinux/arcolinuxl-iso/blob/master/archiso/pacman.conf

}

setup_pacman_conf && export -f setup_pacman_conf # execute the function and export it for chroot / main system


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
echo "##### assigning all variables at once to export into arch-chroot #########"
echo "##########################################################################"

read -ep "$(tput setaf 2)Enter your HostName(tv) : $(tput sgr0)"               hostname && export hostname

read -ep "$(tput setaf 2)Enter Your UserName : $(tput sgr0)"                   username && export username
read -ep "$(tput setaf 2)Enter Your UserPass : $(tput sgr0)"                   userpass && export userpass

read -ep "$(tput setaf 2)Enter Your RootPass : $(tput sgr0)"                   rootpass && export rootpass



echo "##########################################################################"
echo "######################## partitioning the disk ###########################"
echo "##########################################################################"

lsblk -p  ## -p => prints full device path
# $fdisk -l (alternetive shows full drive name with /dev/sdaX) 

tput setaf 3 # Yellow Color
echo "##########################################################################################"
echo "#                                THIS IS A BTRFS INSTALL                                 #"
echo "# YOU DON'T NEED TO DELETE AND RE-CREATE SAME PARTITIONS TO FORMAT IF IT'S ALREADY THERE #"
echo "#          THE SCRIPT WILL DELETE THE SELECTED PARTITION (NOT DRIVE) AUTOMATICALLY       #"
echo "#                JUST ENTER IN CFDISK CHECK EVERYTHING GOOD THEN QUIT                    #"
echo "##########################################################################################"
tput sgr0  # Reset Color

read -ep "$(tput setaf 2)Enter the drive (e.g. /dev/sda) : $(tput sgr0)"  drive 
cfdisk $drive 

sleep 2s
lsblk -p  ## -p => prints full device path

######## how to wipe your file signature/ complete wipe your disk or partition ############
# wipefs -a /dev/sda  ###(to wipe only all file signature) faster method ===>recommended 
# wipefs -t ext4 /dev/sda  ###(to wipe only specific file signature only not all file signature) faster method (never tried)
# dd if=/dev/zero of=/dev/sda bs=1M  ###(to complete wipe full file system or full partition by adding random data 1 time)
# shred -vfz /dev/sda ###(to complete wipe full file system or full partition by adding random data 4 time) (most secure way. time taking) not good for ssd life
# shred -n 1 -vfz /dev/sda ### (-n 1 means format 1 time. by default its 4 time , -v = verbose , -f = force , -z = fill with zero and -s <num> = fill with any number not just zero , -u file.txt , -r -u my_directory to delete all files in a directory recursively

read -ep "$(tput setaf 2)Enter the BOOT partition (e.g. /dev/sdaX) : $(tput sgr0)"  bootpartition 
wipefs -af $bootpartition  # wipe boot file signature forcefully
mkfs.vfat -F32 $bootpartition 

read -ep "$(tput setaf 2)Enter the SWAP partition (e.g. /dev/sdaX) : $(tput sgr0)"  swappartition 
wipefs -af $swappartition # wipe swap file signature forcefully
mkswap $swappartition -f    ###-f = forcefully if any error there
swapon $swappartition

read -ep "$(tput setaf 2)Enter the LINUX partition (e.g. /dev/sdaX) : $(tput sgr0)"  linuxpartition 
wipefs -af $linuxpartition  # wipe linux file signature forcefully 
mkfs.btrfs $linuxpartition -f   ###-f = forcefully if any error there

sleep 10s #check all correct above
	mount $linuxpartition /mnt
	
	btrfs su cr /mnt/@
	btrfs su cr /mnt/@home
#	btrfs su cr /mnt/@root
	btrfs su cr /mnt/@srv
	btrfs su cr /mnt/@tmp
#	btrfs su cr /mnt/@.snapshots
	btrfs su cr /mnt/@var_log
	btrfs su cr /mnt/@var_pkg

	btrfs su li /mnt 

	umount /mnt 

	mountpoint="defaults,noatime,compress=zstd,discard=async,space_cache=v2,autodefrag,commit=120"
	mount -o "$mountpoint",subvol=@             $linuxpartition /mnt
	mkdir -p /mnt/{home,root,srv,var/{log,cache/pacman/pkg},tmp,.snapshots}

	# I'm setting options manually otherwise it will set some options automatically (this will reflect in /etc/fstab)
	mount -o "$mountpoint",subvol=@home         $linuxpartition /mnt/home
#	mount -o "$mountpoint",subvol=@root         $linuxpartition /mnt/root
	mount -o "$mountpoint",subvol=@srv          $linuxpartition /mnt/srv
	mount -o "$mountpoint",subvol=@tmp          $linuxpartition /mnt/tmp
#	mount -o "$mountpoint",subvol=@.snapshots   $linuxpartition /mnt/.snapshots

	# fixing. pkg rollback fully & properly after snapshot restore ## now you can reinstall same package after restoring the snapshot #timeshift fixed
	mount -o "$mountpoint",subvol=@var_log      $linuxpartition /mnt/var/log
	mount -o "$mountpoint",subvol=@var_pkg      $linuxpartition /mnt/var/cache/pacman/pkg


	##### others option you can use above #######################################################################
	# ssd, ==> if you are using the ssd
	#
	# compress=zstd (auto select compression level) (automatically and recommended) <<<=====================
	# compress=zstd:3 (good for HDD)(compress almost all files expect some)(low compression faster R/W speed) 
	# compress-force=zstd:15 (good for SSD)(compress all files forcefully)(high compression low R/W speed)
	# if you are storing mp3,mp4,zip it's better to use low or no compression because files are already compressed
	# you can use any number of compression b/w 1 to 15 
	#
	# discard=async,space_cache=v2, ==>>> if you dont add this option it will automatically be added in /etc/fstab
	# autodefrag ===>> will automatically defrag your btrfs file system :)
	# @var ===>> this subvolume is fixing timeshift snapshots not deleting error :)
	##############################################################################################################
	

	# fixing timeshift snapshot not deleting error | will maybe break systemd-nspawn but docker is a good alternative
	# btrfs subvolume delete /mnt/var/lib/{machines,portables}
	mkdir -p /mnt/var/lib/{machines,portables} # creating regular directory at there place    #timeshift fixed



	mkdir -p /mnt/boot/efi
	mount $bootpartition /mnt/boot/efi



lsblk -p  ## -p => prints full device path
sleep 5s

echo "##########################################################################"
echo "######################### fixing archlinux keyring #######################"
echo "##########################################################################"


pacman --noconfirm -Syyy archlinux-keyring reflector

iso=$(curl -4 ifconfig.co/country-iso)
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
# reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist  # old way
# you can try : https://wiki.archlinux.org/title/mirrors

# ---------------------update your pacman keyring------------------------#

# after booting into Arch Live ISO Wait for 1 minute (don't run any command). it will use your internet to automatic sync/configure some files for your machine otherwise you may face keyring issue

# archlinux-keyring-wkd-sync (--or--) /usr/bin/archlinux-keyring-wkd-sync   # (it refresh the priviously imported keyring)
# if this above command is not working only then try billow commands

# pacman -Syyy
# pacman-key --init               <<<<<<<<<<<<----------------------------  # (it first deletes the priviously imported keyring and then assign new keyring)
# pacman-key --populate
# pacman-key --refresh-keys

# timedatectl set-ntp true #(default is true already)
# timedatectl set-timezone Asia/Kolkata

# pacman -S archlinux-keyring     # if this failed by (invalid or corrupted package (PGP signature)) then
#	pacman -Sc ; pacman -Scc
#	rm -rf /etc/pacman.d/gnupg/*  # and run every above command again

# pacman -S reflector
# 	  mirror='sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist'
# 	  mirrora='sudo reflector --latest 30 --number 10 --sort age --save /etc/pacman.d/mirrorlist'
# 	  mirrord='sudo reflector --latest 30 --number 10 --sort delay --save /etc/pacman.d/mirrorlist'
# 	  mirrors='sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist'
# 	  mirrorx='sudo reflector --age 6 --latest 20  --fastest 20 --threads 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist'
# reboot your system if problem is not fixed

# for more details : https://wiki.archlinux.org/title/Pacman/Package_signing

echo "##########################################################################"
echo "########################## installing base system ########################"
echo "##########################################################################"

### what kernal do you want to use
# what ever the linux kernal you are using here you also need to change it in linux-headers if you are using it
# linux
# linux-hardened
# linux-lts
# linux-zen

pacstrap /mnt base base-devel linux-lts linux-firmware neovim btrfs-progs sed
   
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
rm -rf /mnt/install2.sh

# after running the #part2 unmount /mnt and reboot
echo "unmount /mnt && exit script in 10 second"
echo "you can use ## 'arch-chroot /mnt'  now "
sleep 10s
umount -R /mnt

echo "installaion DONE you can reboot now"
exit























#part22

echo "##########################################################################"
echo "########################### setting up clock #############################"
echo "##########################################################################"

# setup your timezone
# file is already in your system you just need to link it with other location
# time_zone="$(curl --fail https://ipapi.co/timezone)" ### time_zone variable will return your timezone automatically ### Added this from arch wiki https://wiki.archlinux.org/title/System_time

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

#echo "write HostName/NickName for the OS(tv): "
#read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts


echo "##########################################################################"
echo "########### setting up /etc/pacman.conf (for Main System) ################"
echo "##########################################################################"

setup_pacman_conf # executing exported function to setup pacman.conf for main system
pacman -Syyy



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
echo "######################## installing Chaotic AUR ##########################"
echo "##########################################################################"
##-----------------------------------------------------------------------------##
pacman-key --recv-key  3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB

pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'  
##------------------------------ OR (uncomment one)----------------------------##
# pacman -S arcolinux_repo_3party/chaotic-keyring
# pacman -S arcolinux_repo_3party/chaotic-mirrorlist
##-----------------------------------------------------------------------------##

echo "
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf

pacman -Syyy
# source https://aur.chaotic.cx/


echo "##########################################################################"
echo "###################### install all needed packages #######################"
echo "##########################################################################"

pkgs=(

############### Display pkg ################
xorg-server
xorg-apps
xorg-xinit
mesa
intel-ucode  # amd-ucode (for AMD graphics)
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
repgrep # better replacement of "ripgrep"

### fonts ###
ttf-iosevka-nerd
ttf-indic-otf # hindi fonts
noto-fonts
noto-fonts-emoji 

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
engrampa # "file-roller" have more option but it's theming is odd (second best option would be "xarchiver")
yt-dlp
meld
reflector
unclutter # hide cursor after some time
xdotool   # for autotype
# catfish

#### themes ####
lxappearance
qt5ct
# a-candy-beauty-icon-theme-git
# sweet-cursor-theme-git
# sweet-gtk-theme-dark
xcursor-breeze
arc-blackest-theme-git
surfn-icons-git
# epapirus-icon-theme

#### for zsh ####
zsh
zsh-fast-syntax-highlighting  # better replacement of "zsh-syntax-highlighting"
# zsh-autosuggestions

#### user app ####
firefox
obsidian
flameshot


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
echo "###################### setting up root user password #####################"
echo "##########################################################################"

#echo "set password for root user"
#passwd

echo "root:$rootpass" | chpasswd

#usernam: root
#password:


echo "##########################################################################"
echo "################## creating New USER with Default shell ##################"
echo "##########################################################################"

#echo "Enter Your Username : "
#read username

##### cleaning up Default bash bloat (prevent useless files to copy form /etc/skel to home directory on new user creation) #####
rm -rf /etc/skel/.bash*  ## this files are not required even if you are using your default shell as bash

useradd -m -g users -G audio,video,network,wheel,storage,rfkill -s $(which zsh) $username   
# -s means --shell , -m means create home directory for the newuser with the same name as username

#passwd $username

echo "$username:$userpass" | chpasswd

###### changing default shell for the USER you can use this method or above line of code ########
# chsh -s $(which zsh) $username   ## -s means --shell

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

systemctl enable NetworkManager     # don't put --now will give you error
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
                    usermod -aG vboxsf $username  # normal user read-write access on shared folder
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
./home/$username/.bin/1_setup_all.sh



