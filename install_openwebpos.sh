#!/bin/bash

user=$(whoami)
machine_ip=$(hostname -I | awk '{print $1}')

# Install OpenWebPOS Components
sudo apt update
sudo apt upgrade -y
sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
sudo apt install python3-venv
sudo apt install nginx

# Create the project directory
mkdir /home/"$user"/openwebpos

# Change to the project directory
cd /home/"$user"/openwebpos || exit

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install wheel
pip install gunicorn
pip install openwebpos --pre

# Create the OpenWebPOS wsgi file
touch /home/"$user"/openwebpos/wsgi.py

# Add the OpenWebPOS wsgi file contents
echo "from openwebpos import open_web_pos
      app = open_web_pos()
      if __name__ == '__main__':
      app.run()" >>/home/"$user"/openwebpos/wsgi.py

deactivate

# Create the OpenWebPOS systemd service file
sudo touch /etc/systemd/system/openwebpos.service

# Add the OpenWebPOS systemd service file contents
echo "[Unit]
      Description=Gunicorn instance to serve OpenWebPOS
      After=network.target

      [Service]
      User=$user
      Group=www-data
      WorkingDirectory=/home/$user/openwebpos" >>/etc/systemd/system/openwebpos.service
echo "Environment=""PATH=/home/$user/openwebpos/venv/bin""
      ExecStart=/home/$user/openwebpos/venv/bin/gunicorn --bind unix:openwebpos.sock wsgi:app

      [Install]
      WantedBy=multi-user.target" >>/etc/systemd/system/openwebpos.service

# Start the OpenWebPOS systemd service
sudo systemctl start openwebpos

# Enable the OpenWebPOS systemd service
sudo systemctl enable openwebpos

# Configure Nginx
sudo touch /etc/nginx/sites-available/openwebpos

# Add the Nginx configuration file contents
echo "server {
        listen 80;
        server_name $machine_ip;

        location / {
          include proxy_params;
          proxy_pass http://unix:/home/$user/openwebpos/openwebpos.sock;
        }
      }" >>/etc/nginx/sites-available/openwebpos

# Enable the Nginx configuration file
sudo ln -s /etc/nginx/sites-available/openwebpos /etc/nginx/sites-enabled

# Test the Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Add Nginx to the firewall
sudo ufw allow 'Nginx Full'

exit 0
