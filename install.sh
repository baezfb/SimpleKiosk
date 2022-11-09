#!/bin/bash

# Get the current folder directory
folder_dir=$(pwd)

# Update Sources list
cp sources.list /etc/apt/sources.list

# Update & Upgrade
apt-get update && apt-get -y upgrade

# Install non-free packages
apt-get install -y firmware-linux-nonfree firmware-misc-nonfree firmware-realtek firmware-atheros firmware-iwlwifi firmware-amd-graphics

# Ask user if they would be using ssh
read -p "Would you be using ssh? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install UFW Firewall
  apt-get install -y ufw
  # Install OpenSSH Server
  ufw enable
  # Enable SSH
  ufw allow SSH
fi

# Ask user if they would like to install fail2ban
read -p "Would you like to install fail2ban? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install fail2ban
  apt-get install -y fail2ban
  # Copy fail2ban config
  cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  # Restart fail2ban
  service fail2ban restart
  # Enable fail2ban
  systemctl enable fail2ban
fi

# Install NetworkManager
apt-get install -y network-manager

# Install lshw and run it
apt-get install -y lshw
lshw -short >"$HOME"/lshw.html

# Install hwinfo and run it
apt-get install -y hwinfo
hwinfo --short >"$HOME"/hwinfo.html

# Install Core xserver packages
apt-get install -y xserver-xorg-core xinit x11-xserver-utils

# Install video drivers
apt-get install -y xserver-xorg-video-intel xserver-xorg-video-nouveau xserver-xorg-video-ati

# Ask user if they would be using a touchscreen
read -p "Would you be using a touchscreen? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install Touchscreen Drivers
  apt-get install -y xserver-xorg-input-evdev xserver-xorg-input-libinput
fi

# Ask user if they would be using a keyboard
read -p "Would you be using a keyboard? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install Keyboard Drivers
  apt-get install -y xserver-xorg-input-synaptics xserver-xorg-input-kbd
fi

# Ask user if they would be using a mouse
read -p "Would you be using a mouse? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install Mouse Drivers
  apt-get install -y xserver-xorg-input-mouse
fi

# Ask user if they would like to install additional recommended packages
read -p "Would you like to install additional recommended packages? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install additional recommended packages
  apt-get install -y xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable libgl1-mesa-dri mesa-utils
fi

# Add a guest user with home directory and bash shell
useradd -m -s /bin/bash guest

# Set the password for the guest user
echo "guest:guest" | chpasswd

# Create .bash_profile for guest user
cp "$folder_dir"/.bash_profile /home/guest/.bash_profile

# Create .xinitrc for guest user
touch /home/guest/.xinitrc

# Add based data to .xinitrc
echo "#!/bin/bash
xset -dpms
xset s off
xset s noblank" >>/home/guest/.xinitrc

# Ask user if they would be using a website or application
echo "Will you be using a website or application?"
select yn in "Website" "Application"; do
  case $yn in
  Website)
    # Ask user for website url
    read -r -p "What is the website url? " website_url
    # Install Chromium
    apt-get install -y chromium
    # Add website url to .xinitrc
    echo "exec chromium $website_url --start-fullscreen --kiosk --incognito --noerrdialogs --no-first-run --fast --fast-start --disable-infobars --password-store=basic" >>/home/guest/.xinitrc
    break
    ;;
  Application)
    read -r -p "What is the application name? " application_name
    echo "exec $application_name" >>.xinitrc
    break
    ;;
  esac
done

# Change ownership of guest user files
chown -R guest:guest /home/guest

#su -c "$user"

# Ask user if they would like to hide the grub menu and remove splash screen
read -p "Would you like to hide the grub menu and remove splash screen? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # make copy of grub file
  cp /etc/default/grub /etc/default/grub.bak
  # Hide grub menu and remove splash screen
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT=""/g' /etc/default/grub
  sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
  update-grub
fi

# Ask user if they would like to restart the system
read -p "Would you like to restart the system? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Dont forget to copy contents of autologin.conf to getty@tty1.service"
  echo "sudo systemctl edit getty@tty1.service"
  # Restart the system
  sleep 5
  reboot
fi

exit 0
