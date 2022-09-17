#!/bin/bash

mouse="-- -nocursor"

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `install.sh` has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

# Update Sources list
cp sources.list /etc/apt/sources.list

# Update & Upgrade
apt-get update && apt-get upgrade -y

# Install UFW Firewall & Enable
apt-get install ufw -y
ufw enable

# Install Fail2Ban & Enable
apt-get install fail2ban -y
systemctl enable fail2ban

# Fail2Ban Config
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
service fail2ban restart

# Install NetworkManager
apt-get install network-manager -y

# Install iwlwifi-firmware
apt-get install firmware-iwlwifi -y

# Install lshw and hwinfo
apt-get install lshw hwinfo -y

# Run lshw and hwinfo
lshw -short >"$HOME"/lshw.html
hwinfo --short >"$HOME"/hwinfo.html

# Install Chromium
apt-get install chromium -y

# Install Core xserver packages
apt-get install xserver-xorg-core xinit x11-xserver-utils -y

# Find out what video card you have
lspci | grep -i vga

# Ask user what video card they have
echo "What video card do you have? (nvidia, intel, via, amd, generic)"
read videocard

# Install video card drivers  (nvidia, intel, via, amd, generic)
if [ "$videocard" = "nvidia" ]; then
  apt-get install xserver-xorg-video-nouveau -y
elif [ "$videocard" = "intel" ]; then
  apt-get install xserver-xorg-video-intel -y
elif [ "$videocard" = "via" ]; then
  apt-get install xserver-xorg-video-openchrome -y
elif [ "$videocard" = "amd" ]; then
  apt-get install xserver-xorg-video-radeon -y
elif [ "$videocard" = "generic" ]; then
  apt-get install xserver-xorg-video-vesa -y
else
  echo "Invalid video card"
  echo "Installing generic video drivers"
  apt-get install xserver-xorg-video-vesa -y
fi

# Ask user if they will be using keyboard or mouse
echo "Will you be using a keyboard or mouse?"
select yn in "Keyboard" "Mouse"; do
  case $yn in
  Keyboard)
    echo "Installing xserver-xorg-input-kbd"
    apt-get install xserver-xorg-input-kbd -y
    break
    ;;
  Mouse)
    echo "Installing xserver-xorg-input-mouse"
    apt-get install xserver-xorg-input-mouse -y
    mouse=""
    break
    ;;
  esac
done

# Ask user if they will be using a touch screen
echo "Will you be using a touch screen?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Installing xserver-xorg-input-evdev & xserver-xorg-input-synaptics"
    apt-get install xserver-xorg-input-evdev xserver-xorg-input-synaptics -y
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
    apt-get install xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable libgl1-mesa-dri mesa-utils
    break
    ;;
  No) break ;;
  esac
done

# Create a guest user
adduser guest -m -s /bin/sh guest

# Add bash shell to guest user
usrmod -s /bin/bash guest

# Set guest user password
passwd guest

# Switch to guest user
su -c guest

# Change to guest user home directory
cd ~ || exit

# Create .bash_profile
touch .bash_profile

# Add .bash_profile contents
echo "if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
       startx $mouse
      fi" >>.bash_profile

# Create .xinitrc
touch .xinitrc

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

# Exit guest user
exit

# Add the following to getty@tty1.service
echo "[Service]
      ExecStart=
      ExecStart=-/sbin/agetty --noissue --autologin guest --noclear %I $TERM
      Type=idle" >>/lib/systemd/system/getty@tty1.service

# Ask user if they would like to restart the system
echo "Would you like to restart the system?"
select yn in "Yes" "No"; do
  case $yn in
  Yes)
    echo "Restarting the system"
    reboot
    break
    ;;
  No) break ;;
  esac
done

exit 0
