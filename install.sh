#!/bin/bash

mouse="-- -nocursor"

# Get the current username
user=$(whoami)

# Update Sources list
cp sources.list /etc/apt/sources.list

# Update & Upgrade
apt-get update && apt-get -y upgrade

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

# Install Fail2Ban & Enable
apt-get install -y fail2ban
systemctl enable fail2ban

# Fail2Ban Config
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
service fail2ban restart

# Install NetworkManager
apt-get install -y network-manager firmware-realtek firmware-iwlwifi

# Install lshw and run it
apt-get install -y lshw
lshw -short >"$HOME"/lshw.html

# Install hwinfo and run it
apt-get install -y hwinfo
hwinfo --short >"$HOME"/hwinfo.html

# Install Chromium
apt-get install -y chromium

# Install Core xserver packages
apt-get install -y xserver-xorg-core xinit x11-xserver-utils

# Find out what video card you have
lspci | grep -i vga

# Ask user what video card they have
echo "What video card do you have?"
select yn in "Nvidia" "Intel" "VIA" "AMD" "Generic" "ALL"; do
  case $yn in
  Nvidia)
    # Install Nvidia Drivers
    apt-get install -y xserver-xorg-video-nouveau
    break
    ;;
  Intel)
    # Install Intel Drivers
    apt-get install -y xserver-xorg-video-intel
    break
    ;;
  VIA)
    # Install VIA Drivers
    apt-get install -y xserver-xorg-video-openchrome
    break
    ;;
  AMD)
    # Install AMD Drivers
    apt-get install -y xserver-xorg-video-radeon firmware-amd-graphics
    break
    ;;
  Generic)
    # Install Generic Drivers
    apt-get install -y xserver-xorg-video-vesa
    break
    ;;
  ALL)
    # Confirm install of all drivers
    echo "Are you sure you want to install all drivers?"
    select yn in "Yes" "No"; do
      case $yn in
      Yes)
        # Install all drivers
        apt-get install -y xserver-xorg-video-all
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
    apt-get install -y xserver-xorg-input-kbd
    break
    ;;
  Mouse)
    echo "Installing xserver-xorg-input-mouse"
    apt-get install -y xserver-xorg-input-mouse
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
    apt-get install -y xserver-xorg-input-evdev xserver-xorg-input-synaptics
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
    apt-get install -y xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable libgl1-mesa-dri mesa-utils
    break
    ;;
  No) break ;;
  esac
done

# Add guest user
useradd -m -s /bin/bash guest
passwd guest

su -c guest

# Create .bash_profile for guest user
cp /home/"$user"/SimpleKiosk/.bash_profile /home/guest/.bash_profile

touch /home/guest/.xinitrc

# Ask user if they would be using a website or application
echo "Will you be using a website or application?"
select yn in "Website" "Application"; do
  case $yn in
  Website)
    echo "What website would you like to use?"
    read -r website
    echo "#!/bin/bash
    xset -dpms
    xset s off
    xset s noblank
    exec chromium $website --start-fullscreen --kiosk --incognito --noerrdialogs --enable-features=OverlayScrollbar,OverlayScrollbarFlashAfterAnyScrollUpdate,OverlayScrollbarFlashWhenMouseEnter --disable-translate --no-first-run --fast --fast-start --disable-infobars --disable-features=TranslateUI --disk-cache-dir=/dev/null  --password-store=basic" >>/home/guest/.xinitrc
    break
    ;;
  Application)
    echo "What application would you like to use?"
    read -r application
    echo "#!/bin/bash
    xset -dpms
    xset s off
    xset s noblank
    exec $application" >>.xinitrc
    break
    ;;
  esac
done

# Change ownership of guest user files
chown -R guest:guest /home/guest

su -c "$user"

# Ask user if they would like to hide the grub menu
echo "Would you like to hide the grub menu?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Hiding grub menu"
    cp /etc/default/grub /etc/default/grub.bak
    sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
    update-grub
    break
    ;;
  No) break ;;
  esac
done

# Ask user if they would like to restart the system
echo "Would you like to restart the system?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Restarting the system"
    echo "Dont forget to delete SimpleKiosk after reboot"
    echo "sudo rm -rf SimpleKiosk"
    echo "***********************"
    echo "Dont forget to copy contents of autologin.conf to getty@tty1.service"
    echo "sudo systemctl edit getty@tty1.service"
    sleep 5
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
