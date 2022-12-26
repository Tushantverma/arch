sudo pacman -Syyy virtualbox virtualbox-guest-iso
sudo gpasswd -a $USER vboxusers
sudo modprobe vboxdrv
yay -S virtualbox-ext-oracle
sudo systemctl enable vboxweb.service
sudo systemctl start vboxweb.service
lsmod | grep -i vbox