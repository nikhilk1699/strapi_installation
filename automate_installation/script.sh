#!/bin/bash

show_message() {
  echo "-------------------------------------------------------------"
  echo "$1"
  echo "-------------------------------------------------------------"
}

show_message "Update system packages"
sudo apt update

show_message "Install Node.js and npm"
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y
show_message "Update system again"
sudo apt update

show_message "Install PostgreSQL"
sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql.service

show_message "Install Nginx"
sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'
sudo systemctl start nginx

show_message "Update Nginx site configuration"
url=$(curl -s ifconfig.me)
sudo tee /etc/nginx/sites-available/$url <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name $url www.$url;
    location / {
        proxy_pass http://127.0.0.1:1337;
        include proxy_params;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/$url /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

show_message "Configure PostgreSQL"
sudo -i -u postgres createdb strapi
sudo -i -u postgres createuser nikhil
sudo -i -u postgres psql -c "ALTER USER nikhil PASSWORD 'admin';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE strapi TO nikhil;"

show_message "Create Strapi app"
cd /home/linuxusr
yes | npx create-strapi-app@latest my-project \
  --dbclient=postgres \
  --dbhost=127.0.0.1 \
  --dbname=strapi \
  --dbusername=nikhil \
  --dbpassword=admin \
  --dbport=5432

cd /home/linuxusr/my-project
sudo npm install -g pm2

sudo tee server.js <<EOL
 const strapi = require('@strapi/strapi');
 strapi().start();
EOL

pm2 start --name strapi server.js 
pm2 save
pm2 startup

show_message "Strapi app has been started"
