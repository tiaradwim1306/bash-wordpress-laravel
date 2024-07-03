# Install paket
sudo apt update
sudo apt install nginx -y
sudo add-apt-repository ppa:ondrej/php
sudo apt install php8.0 php8.0-fpm php8.0-mysql php8.0-xml php8.0-mbstring php8.0-curl php8.0-bcmath -y

#edit php 
sed -i "s/pm.max_children = 5/pm.max_children = 25/" /etc/php/8.0/fpm/pool.d/www.conf
sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.0/fpm/php.ini
sed -i "s/^post_max_size = .*/post_max_size = 100M/" /etc/php/8.0/fpm/php.ini
sed -i "s/^memory_limit = .*/memory_limit = 512M/" /etc/php/8.0/fpm/php.ini

sudo systemctl restart php8.0-fpm
sudo systemctl restart nginx

#install mysql
wget https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.16-1_all.deb
sudo apt update
sudo apt install mysql-server -y

echo "Wordpress"
#create database Wordpress
sudo mysql -e "CREATE DATABASE wordpress;"
sudo mysql -e "CREATE USER 'wordpress-user'@'localhost' IDENTIFIED BY 'user-pass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* to 'wordpress-user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# source file
sudo apt install unzip -y
wget https://wordpress.org/latest.zip -P /var/www
sudo unzip /var/www/latest.zip -d /var/www
chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress
#SSL
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx certonly -d tiara.efs.my.id
#buat VHost
rm /etc/nginx/sites-enabled/default
touch /etc/nginx/sites-available/wordpress
vhost1="/etc/nginx/sites-available/wordpress"
cat << EOF > $vhost1
server {
    listen 443 ssl;
    server_name tiara.efs.my.id;

    root /var/www/wordpress;
    index index.php index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/tiara.efs.my.id/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tiara.efs.my.id/privkey.pem;

    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
systemctl restart nginx

echo "laravel"
sudo apt install composer -y
sudo apt install php php-fpm php-mysql php-xml php-mbstring php-curl php-bcmath -y
#create database lavarel
sudo mysql -e "CREATE DATABASE laravel;"
sudo mysql -e "CREATE USER 'laravel-user'@'localhost' IDENTIFIED BY 'lavarel-password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON laravel.* to 'laravel-user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
#create project
composer create-project --prefer-dist laravel/laravel /var/www/assesment
#edit file .env
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /var/www/assesment/.env
sed -i "s/# DB_DATABASE=.*/DB_DATABASE=laravel/" /var/www/assesment/.env
sed -i "s/# DB_USERNAME=.*/DB_USERNAME=laravel-user/" /var/www/assesment/.env
sed -i "s/# DB_PASSWORD=.*/DB_PASSWORD=laravel-password/" /var/www/assesment/.env
sed -i "s/# DB_HOST=.*/DB_HOST=127.0.0.1/" /var/www/assesment/.env
sed -i "s/# DB_PORT=.*/DB_PORT=3306/" /var/www/assesment/.env
#permission & table
sudo chown -R www-data:www-data /var/www/assesment
sudo chmod -R 775 /var/www/assesment
php /var/www/assesment/artisan key:generate
php /var/www/assesment/artisan migrate
php /var/www/assesment/artisan session:table
#buat VHost
touch /etc/nginx/sites-available/laravel
vhost2="/etc/nginx/sites-available/laravel"
cat << EOF > $vhost2
server {
    listen 80;
    server_name _;
    root /var/www/assesment/public;

    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel
systemctl restart nginx

echo "Program Selesai"

