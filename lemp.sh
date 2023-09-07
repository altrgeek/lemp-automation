#!/bin/bash

# Updating the package repository and installing necessary packages
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring pwgen wget

# Installing GPG keys for Nginx
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

# Adding PHP repository and GPG key
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg

sleep 3

# Installing LEMP server
sudo apt update
sudo apt install -y snapd nginx php8.1 mariadb-server redis php8.1-common php8.1-fpm php8.1-gd php8.1-intl php8.1-redis php8.1-mbstring php8.1-mysql php8.1-imagick php8.1-xml php8.1-bcmath php8.1-zip php8.1-curl

# Enabling Brotli compression module for Nginx
wget https://github.com/darylounet/libnginx-mod-brotli/releases/download/brotli-1.0.9%2Fnginx-1.24.0-1/libnginx-mod-brotli-dbgsym_1.0.9+nginx-1.24.0-1.bullseye_amd64.deb
wget https://github.com/darylounet/libnginx-mod-brotli/releases/download/brotli-1.0.9%2Fnginx-1.24.0-1/libnginx-mod-brotli_1.0.9+nginx-1.24.0-1.bullseye_amd64.deb

sleep 3
sudo dpkg -i *.deb
sudo rm /etc/nginx/conf.d/brotli.conf
sudo rm /etc/nginx/nginx.conf
mv nginx.conf /etc/nginx/nginx.conf
chown root:root /etc/nginx/nginx.conf
chmod 644 /etc/nginx/nginx.conf

sleep 3
# Prompt the user for input
read -p "Enter the domain name: " replace_string

# Perform the search and replace
if [ -f vhost.conf ]; then
  # Use sed to perform the replacement and save the changes in-place
  sed -i "s/selfinvest.is/$replace_string/g" vhost.conf
  echo "Search and replace operation completed in vhost.conf."
else
  echo "File not found: vhost.conf"
fi

sudo mv vhost.conf /etc/nginx/conf.d/$replace_string
sudo mkdir -p /var/www/html/$replace_string
sudo mv html /var/www/html/$replace_string
sudo chown -R nginx:www-data /var/www/html/$replace_string
sudo chmod -R 775 /var/www/html/$replace_string
sudo usermod -a -G www-data  nginx
sleep 3

# Generate a secure password for the MariaDB user
mysql_password=$(pwgen -1s 16)
echo "MariaDB root password: $mysql_password" # Display the MariaDB root password, please save it securel
# Create the database and user
sudo mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wpdb_001;
CREATE USER 'wpu_xft65g'@'localhost' IDENTIFIED BY '${mysql_password}';
GRANT ALL PRIVILEGES ON wpdb_001.* TO 'wpu_xft65g'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

sleep 3
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Display information about the created MariaDB user and database
echo "MariaDB Database: wpdb_001"
echo "MariaDB User: wpu_xft65g"
echo "MariaDB Password: $mysql_password"
echo "Please run mysql -u wpu_xft65g -p wpdb_001 < db.sql"
