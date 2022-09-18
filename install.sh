#!/bin/bash

mouse="-- -nocursor"

# Get the current username
user=$(whoami)

## Ask for the administrator password upfront
#sudo -v

# Keep-alive: update existing `sudo` time stamp until `install.sh` has finished
#while true; do
#  sudo -n true
#  sleep 60
#  kill -0 "$$" || exit 0
#done 2>/dev/null &

# Update Sources list
sudo cp sources.list /etc/apt/sources.list

# Update & Upgrade
sudo apt-get update && sudo apt-get upgrade -y

# Ask user if they would be using ssh
read -p "Would you be using ssh? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Install UFW Firewall
  sudo apt-get install ufw -y
  # Install OpenSSH Server
  sudo ufw enable
  # Enable SSH
  sudo ufw allow SSH
fi

# Install Fail2Ban & Enable
sudo apt-get install fail2ban -y
sudo systemctl enable fail2ban

# Fail2Ban Config
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo service fail2ban restart

# Install NetworkManager
sudo apt-get install network-manager -y

# Install iwlwifi-firmware
sudo apt-get install firmware-iwlwifi -y

# Install lshw and run it
sudo apt-get install lshw -y
lshw -short >"$HOME"/lshw.html

# Install hwinfo and run it
sudo apt-get install hwinfo -y
hwinfo --short >"$HOME"/hwinfo.html

# Install Chromium
sudo apt-get install chromium -y

# Install Core xserver packages
sudo apt-get install xserver-xorg-core xinit x11-xserver-utils -y

# Find out what video card you have
lspci | grep -i vga

# Ask user what video card they have
echo "What video card do you have?"
select yn in "Nvidia" "Intel" "VIA" "AMD" "Generic" "ALL"; do
  case $yn in
  Nvidia)
    # Install Nvidia Drivers
    sudo apt-get install xserver-xorg-video-nouveau -y
    break
    ;;
  Intel)
    # Install Intel Drivers
    sudo apt-get install xserver-xorg-video-intel -y
    break
    ;;
  VIA)
    # Install VIA Drivers
    sudo apt-get install xserver-xorg-video-openchrome -y
    break
    ;;
  AMD)
    # Install AMD Drivers
    sudo apt-get install xserver-xorg-video-radeon -y
    break
    ;;
  Generic)
    # Install Generic Drivers
    sudo apt-get install xserver-xorg-video-vesa -y
    break
    ;;
  ALL)
    # Confirm install of all drivers
    echo "Are you sure you want to install all drivers?"
    select yn in "Yes" "No"; do
      case $yn in
      Yes)
        # Install all drivers
        sudo apt-get install xserver-xorg-video-all -y
        ;;
      No)
        break
        ;;
      esac
    done
    break
    ;;
  esac
done

# Ask user if they will be using keyboard or mouse
echo "Will you be using a keyboard or mouse?"
select yn in "Keyboard" "Mouse" "No"; do
  case $yn in
  Keyboard)
    echo "Installing xserver-xorg-input-kbd"
    sudo apt-get install xserver-xorg-input-kbd -y
    break
    ;;
  Mouse)
    echo "Installing xserver-xorg-input-mouse"
    sudo apt-get install xserver-xorg-input-mouse -y
    mouse=""
    break
    ;;
  No) break ;;
  esac
done

# Ask user if they will be using a touch screen
echo "Will you be using a touch screen?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Installing xserver-xorg-input-evdev & xserver-xorg-input-synaptics"
    sudo apt-get install xserver-xorg-input-evdev xserver-xorg-input-synaptics -y
    break
    ;;
  No) break ;;
  esac
done

# Ask user if they would like to install additional recommended packages
echo "Would you like to install additional recommended packages?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Installing additional recommended packages"
    sudo apt-get install xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable libgl1-mesa-dri mesa-utils
    break
    ;;
  No) break ;;
  esac
done

# Check if guest user exists
if id -u guest >/dev/null 2>&1; then
  echo "Guest user exists"
else
  echo "Guest user does not exist"
  # Create a guest user
  sudo useradd -m -s /bin/sh guest
  # Set guest user password
  sudo passwd guest
fi

# Check if guest user in /bin/bash
if sudo grep -q "/bin/bash" /etc/passwd; then
  echo "Guest user is in /bin/bash"
else
  echo "Guest user is not in /bin/bash"
  # Change guest user shell to /bin/bash
  sudo usermod -s /bin/bash guest
fi

# Create systemd/system file for guest user
sudo touch /etc/systemd/system/getty@tty1.service

# Autologin guest user
echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin guest --noclear %I $TERM
Type=idle" | sudo tee -a /lib/systemd/system/getty@tty1.service >/dev/null

## Switch to guest user
#su -c guest
sudo su -c - guest

# Change to guest user home directory
cd /home/guest || exit

# Check if .bash_profile exists
if [ -f .bash_profile ]; then
  echo ".bash_profile exists"
  # Remove .bash_profile
  rm .bash_profile
  # Create .bash_profile
  touch .bash_profile
else
  echo ".bash_profile does not exist"
  # Create .bash_profile
  touch .bash_profile
fi

# Add .bash_profile contents
echo "if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
 startx $mouse
fi" >>.bash_profile

# Check if .xinitrc exists
if [ -f .xinitrc ]; then
  echo ".xinitrc exists"
  # Remove .xinitrc
  echo "Removing .xinitrc"
  rm .xinitrc
  # Create .xinitrc
  echo "Creating .xinitrc"
  touch .xinitrc
else
  echo ".xinitrc does not exist"
  echo "Creating .xinitrc"
  # Create .xinitrc
  touch .xinitrc
fi

# Ask user if they would be using a website or application
echo "Will you be using a website or application?"
select yn in "Website" "Application"; do
  case $yn in
  Website)
    echo "What website would you like to use?"
    read -r website
    echo "exec chromium $website --start-fullscreen --kiosk --incognito --noerrdialogs --enable-features=OverlayScrollbar,OverlayScrollbarFlashAfterAnyScrollUpdate,OverlayScrollbarFlashWhenMouseEnter --disable-translate --no-first-run --fast --fast-start --disable-infobars --disable-features=TranslateUI --disk-cache-dir=/dev/null  --password-store=basic" >>.xinitrc
    break
    ;;
  Application)
    echo "What application would you like to use?"
    read -r application
    echo "exec $application" >>.xinitrc
    break
    ;;
  esac
done

# Switch back to original user
su -c "$user"

# Ask user if they would like to restart the system
echo "Would you like to restart the system?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Restarting the system"
    echo "Dont forget to delete SimpleKiosk after reboot"
    wait 5
    sudo reboot
    break
    ;;
  No)
    echo "Deleting SimpleKiosk directory"
    rm -rf SimpleKiosk
    break
    ;;
  esac
done

echo "SimpleKiosk has finished installing"
echo "Dont forget to restart the system"
echo "Goodbye..."

exit 0
