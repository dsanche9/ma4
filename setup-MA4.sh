#!/bin/bash
sudo bash

sudo apt-get -y update 1>/tmp/01.out 2>/tmp/01.err
sudo apt-get -y upgrade 1>/tmp/01.out 2>/tmp/01.err
sudo apt-get -y install apache2 wget php5 php5-curl curl php5-mysql git 1>/tmp/02.out 2>/tmp/02.err

curl -sS https://getcomposer.org/installer | php
git clone https://github.com/dsanche9/ma4.git
mv ma4/composer.json composer.json
sudo php composer.phar install
sudo cat 'extensions=json.so' >> /etc/php5/apache2/php.ini
mv ma4/index.php index.php
mv ma4/result.php result.php
service apache2 restart 1>/tmp/01.out 2>/tmp/01.err
sudo chmod 777 /var/www/html/

mv composer.phar /var/www/html
mv composer.json /var/www/html
mv vendor /var/www/html

mv composer.lock /var/www/html
mv index.php /var/www/html
mv result.php /var/www/html
rm /var/www/html/index.html



