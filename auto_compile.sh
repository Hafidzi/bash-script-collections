#!/bin/bash

# Apache + OpenSSL (Forward Secrecy) + PHP auto-compilation & installation script
# Written and provided by https://hacking.im
# Last updated 2014-04-08 (April 8th, 2014)
title="Apache + OpenSSL (Forward Secrecy) + PHP auto-compilation & installation script"
package="auto_compile.sh"

# Versions last updated 2014-10-20 (October 20th, 2014)
# Update or change version numbers here to install different versions
APACHE_VERSION="2.4.17" # Source http://httpd.apache.org/
OPENSSL_VERSION="1.0.2d" # Source http://www.openssl.org/source/
APR_VERSION="1.5.2" # Source https://apr.apache.org/
APR_UTIL_VERSION="1.5.4" # Source https://apr.apache.org/
PHP_VERSION="5.6.15" # Source http://us1.php.net/downloads.php

# Build directory location, used for downloading / compilation
BUILD_DIRECTORY="/root/build" # No trailing slash
UPDATE_BASE_SYSTEM="TRUE"

# Self-signed certificate options
CSR_COMMON_NAME=`hostname`
CSR_CITY="Toronto"
CSR_STATE="Ontario"
CSR_COUNTRY="CA"
CSR_ORGANIZATION=""
CSR_DEPARTMENT=""
CSR_KEY_SIZE="4096"

APACHE_CONF_LOCATION="/usr/local/apache2/conf/httpd.conf"
APACHE_SSL_CONF_LOCATION="/usr/local/apache2/conf/extra/httpd-ssl.conf"

show_help () {
	echo "$title"
	echo " "
	echo "$package [options]"
	echo " "
	echo "options:"
	echo "-h, --help                show brief help"
	echo "-i, --install             run this for first-time installation"
	echo "-u, --update              update existing installation"
	exit 0
}

if [ "$1" == "" ]; then
	show_help
fi

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        show_help
                        ;;
                -i|--install)
                        INSTALL_TYPE="INSTALL"
						shift
                        ;;
                -u|--update)
                        INSTALL_TYPE="UPDATE"
						shift
                        ;;
                *)
						show_help
        esac
done

# Install Atomic repository
if [ "$INSTALL_TYPE" == "INSTALL" ]; then
	echo "[*] Installing Atomic repository"
	wget -q -O - http://www.atomicorp.com/installers/atomic | sh
fi
# Update the base system
if [ "$UPDATE_BASE_SYSTEM" == "TRUE" ]; then
	echo "[*] Updating base system"
	yum -y update
fi

if [ "$INSTALL_TYPE" == "INSTALL" ]; then
	echo "[*] INSTALL Mode - Installing 'Development Tools' package group"
	yum -y groupinstall "Development Tools"
	echo "[*] INSTALL Mode - Installing build dependencies"
	yum -y install pcre-devel gcc make automake autoconf perl.x86_64 httpd-devel.x86_64 libxml2-devel.x86_64 openssl-devel.x86_64 pcre-devel.x86_64 bzip2-devel.x86_64 curl-devel.x86_64 enchant-devel.x86_64 libjpeg-devel.x86_64 libjpeg-turbo-devel.x86_64 libpng-devel.x86_64 libXpm-devel.x86_64 freetype-devel.x86_64 gmp-devel.x86_64 libicu-devel.x86_64 gcc-c++ libmcrypt-devel.x86_64 postgresql-devel.x86_64 aspell-devel.x86_64 libedit-devel.x86_64 recode-devel.x86_64 net-snmp-devel.x86_64 libtidy-devel.x86_64 libxslt-devel.x86_64 libcurl-devel.x86_64 libtool-ltdl-devel.x86_64 libvpx-devel.x86_64 t1lib-devel.x86_64 readline-devel.x86_64
fi

# Make build directory if does not exist
echo "[*] Creating build directory $BUILD_DIRECTORY if it doesn't exist"
mkdir -p $BUILD_DIRECTORY
cd $BUILD_DIRECTORY

# Remove any previous OpenSSL version
echo "[*] Removing any old archives and build directories for OpenSSL"
rm -rf openssl-*

# Download version of OpenSSL
echo "[*] Downloading OpenSSL $OPENSSL_VERSION"
wget http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz -O openssl-$OPENSSL_VERSION.tar.gz

# Extract
echo "[*] Extracting OpenSSL $OPENSSL_VERSION"
tar zxvf openssl-$OPENSSL_VERSION.tar.gz
cd openssl-$OPENSSL_VERSION

# Use -DOPENSSL_NO_HEARTBEATS option to mitigate Heartbleed vulnerability ( CVE-2014-0160 ) http://heartbleed.com/
echo "[*] Configuring / Building OpenSSL"
./config --prefix=/opt/openssl-$OPENSSL_VERSION --openssldir=/opt/openssl-$OPENSSL_VERSION  -DOPENSSL_NO_HEARTBEATS
make
make install

# Change back to build directory
cd $BUILD_DIRECTORY

# Remove any previous Apache / APR / APR Utility versions
echo "[*] Removing any old archives and build directories for Apache / Apache Portable Runtime"
rm -rf httpd-*
rm -rf apr-*

# Download Apache / APR / APR Utility versions
echo "[*] Downloading Apache $APACHE_VERSION / Apache Portable Runtime $APR_VERSION / APR Utility $APR_UTIL_VERSION"
wget http://mirror.its.dal.ca/apache/httpd/httpd-$APACHE_VERSION.tar.gz -O httpd-$APACHE_VERSION.tar.gz
wget http://apache.parentingamerica.com/apr/apr-$APR_VERSION.tar.gz -O apr-$APR_VERSION.tar.gz
wget http://apache.parentingamerica.com/apr/apr-util-$APR_UTIL_VERSION.tar.gz -O apr-util-$APR_UTIL_VERSION.tar.gz

# Extract Apache
echo "[*] Extracting Apache $APACHE_VERSION / Apache Portable Runtime $APR_VERSION / APR Utility $APR_UTIL_VERSION"
tar zxvf httpd-$APACHE_VERSION.tar.gz
cd httpd-$APACHE_VERSION/srclib/

# Extract APR
echo "[*] Extracting Apache Portable Runtime $APR_VERSION"
tar zxvf ../../apr-$APR_VERSION.tar.gz
ln -s apr-$APR_VERSION/ apr

# Extract APR-UTIL
echo "[*] Extracting Apache Portable Runtime Utility $APR_UTIL_VERSION"
tar zxvf ../../apr-util-$APR_UTIL_VERSION.tar.gz
ln -s apr-util-$APR_UTIL_VERSION/ apr-util

# Up one level to configure and build Apache
echo "[*] Configuring / Building Apache"
cd ..
./configure --with-included-apr --enable-ssl --with-ssl=/opt/openssl-$OPENSSL_VERSION --enable-ssl-staticlib-deps --enable-mods-static=ssl
make

# Stop Apache 
echo "[*] Stopping currently running Apache installation"
service httpd stop
echo "[*] Installing Apache $APACHE_VERSION"
make install

# Change back to build directory
cd $BUILD_DIRECTORY/

# Download PHP
echo "[*] Downloading PHP $PHP_VERSION"
wget http://us1.php.net/get/php-$PHP_VERSION.tar.gz/from/this/mirror -O php-$PHP_VERSION.tar.gz

# Extract PHP
echo "[*] Extracting PHP $PHP_VERSION"
tar zxvf php-$PHP_VERSION.tar.gz
cd php-$PHP_VERSION

# Configure & Compile
echo "[*] Configuring / Building PHP"
./configure --with-libdir=lib64 --prefix=/usr/local --with-layout=PHP --with-pear --with-apxs2=/usr/local/apache2/bin/apxs --enable-calendar --enable-bcmath --with-gmp --enable-exif --with-mcrypt --with-mhash --with-zlib --with-bz2 --enable-zip --enable-ftp --enable-mbstring --with-iconv --enable-intl --with-icu-dir=/usr --with-gettext --with-pspell --enable-sockets --with-openssl --with-curl --with-curlwrappers --with-gd --enable-gd-native-ttf --with-jpeg-dir=/usr --with-png-dir=/usr --with-zlib-dir=/usr --with-xpm-dir=/usr --with-vpx-dir=/usr --with-freetype-dir=/usr --with-t1lib=/usr --with-libxml-dir=/usr --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-soap --with-xmlrpc --with-xsl --with-tidy=/usr --with-readline --enable-pcntl --enable-sysvshm --enable-sysvmsg --enable-shmop --with-openssl --with-openssl-dir=/opt/openssl-$OPENSSL_VERSION/include/
make

echo "[*] Installing PHP $PHP_VERSION"
make install

INIT_FILE="IyEvYmluL2Jhc2gKIwojIFN0YXJ0dXAgc2NyaXB0IGZvciB0aGUgQXBhY2hlIFdlYiBTZXJ2ZXIKIwojIGNoa2NvbmZpZzogLSA4NSAxNQojIGRlc2NyaXB0aW9uOiBBcGFjaGUgaXMgYSBXb3JsZCBXaWRlIFdlYiBzZXJ2ZXIuICBJdCBpcyB1c2VkIHRvIHNlcnZlIFwKIyAgICAgICAgICAgICAgSFRNTCBmaWxlcyBhbmQgQ0dJLgojIHByb2Nlc3NuYW1lOiBodHRwZAojIHBpZGZpbGU6IC91c3IvbG9jYWwvYXBhY2hlMi9sb2dzL2h0dHBkLnBpZAojIGNvbmZpZzogL3Vzci9sb2NhbC9hcGFjaGUyL2NvbmYvaHR0cGQuY29uZgogCiMgU291cmNlIGZ1bmN0aW9uIGxpYnJhcnkuCi4gL2V0Yy9yYy5kL2luaXQuZC9mdW5jdGlvbnMKIAppZiBbIC1mIC9ldGMvc3lzY29uZmlnL2h0dHBkIF07IHRoZW4KICAgICAgICAuIC9ldGMvc3lzY29uZmlnL2h0dHBkCmZpCiAKIyBUaGlzIHdpbGwgcHJldmVudCBpbml0bG9nIGZyb20gc3dhbGxvd2luZyB1cCBhIHBhc3MtcGhyYXNlIHByb21wdCBpZgojIG1vZF9zc2wgbmVlZHMgYSBwYXNzLXBocmFzZSBmcm9tIHRoZSB1c2VyLgpJTklUTE9HX0FSR1M9IiIKIAojIFBhdGggdG8gdGhlIGFwYWNoZWN0bCBzY3JpcHQsIHNlcnZlciBiaW5hcnksIGFuZCBzaG9ydC1mb3JtIGZvciBtZXNzYWdlcy4KYXBhY2hlY3RsPS91c3IvbG9jYWwvYXBhY2hlMi9iaW4vYXBhY2hlY3RsCmh0dHBkPS91c3IvbG9jYWwvYXBhY2hlMi9iaW4vaHR0cGQKcGlkPSRodHRwZC9sb2dzL2h0dHBkLnBpZApwcm9nPWh0dHBkClJFVFZBTD0wCiAKIAojIFRoZSBzZW1hbnRpY3Mgb2YgdGhlc2UgdHdvIGZ1bmN0aW9ucyBkaWZmZXIgZnJvbSB0aGUgd2F5IGFwYWNoZWN0bCBkb2VzCiMgdGhpbmdzIC0tIGF0dGVtcHRpbmcgdG8gc3RhcnQgd2hpbGUgcnVubmluZyBpcyBhIGZhaWx1cmUsIGFuZCBzaHV0ZG93bgojIHdoZW4gbm90IHJ1bm5pbmcgaXMgYWxzbyBhIGZhaWx1cmUuICBTbyB3ZSBqdXN0IGRvIGl0IHRoZSB3YXkgaW5pdCBzY3JpcHRzCiMgYXJlIGV4cGVjdGVkIHRvIGJlaGF2ZSBoZXJlLgpzdGFydCgpIHsKICAgICAgICBlY2hvIC1uICQiU3RhcnRpbmcgJHByb2c6ICIKICAgICAgICBkYWVtb24gJGh0dHBkICRPUFRJT05TCiAgICAgICAgUkVUVkFMPSQ/CiAgICAgICAgZWNobwogICAgICAgIFsgJFJFVFZBTCA9IDAgXSAmJiB0b3VjaCAvdmFyL2xvY2svc3Vic3lzL2h0dHBkCiAgICAgICAgcmV0dXJuICRSRVRWQUwKfQpzdG9wKCkgewogICAgICAgIGVjaG8gLW4gJCJTdG9wcGluZyAkcHJvZzogIgogICAgICAgIGtpbGxwcm9jICRodHRwZAogICAgICAgIFJFVFZBTD0kPwogICAgICAgIGVjaG8KICAgICAgICBbICRSRVRWQUwgPSAwIF0gJiYgcm0gLWYgL3Zhci9sb2NrL3N1YnN5cy9odHRwZCAkcGlkCn0KcmVsb2FkKCkgewogICAgICAgIGVjaG8gLW4gJCJSZWxvYWRpbmcgJHByb2c6ICIKICAgICAgICBraWxscHJvYyAkaHR0cGQgLUhVUAogICAgICAgIFJFVFZBTD0kPwogICAgICAgIGVjaG8KfQogCiMgU2VlIGhvdyB3ZSB3ZXJlIGNhbGxlZC4KY2FzZSAiJDEiIGluCiAgc3RhcnQpCiAgICAgICAgc3RhcnQKICAgICAgICA7OwogIHN0b3ApCiAgICAgICAgc3RvcAogICAgICAgIDs7CiAgc3RhdHVzKQogICAgICAgIHN0YXR1cyAkaHR0cGQKICAgICAgICBSRVRWQUw9JD8KICAgICAgICA7OwogIHJlc3RhcnQpCiAgICAgICAgc3RvcAogICAgICAgIHN0YXJ0CiAgICAgICAgOzsKICBjb25kcmVzdGFydCkKICAgICAgICBpZiBbIC1mICRwaWQgXSA7IHRoZW4KICAgICAgICAgICAgICAgIHN0b3AKICAgICAgICAgICAgICAgIHN0YXJ0CiAgICAgICAgZmkKICAgICAgICA7OwogIHJlbG9hZCkKICAgICAgICByZWxvYWQKICAgICAgICA7OwogIGdyYWNlZnVsfGhlbHB8Y29uZmlndGVzdHxmdWxsc3RhdHVzKQogICAgICAgICRhcGFjaGVjdGwgJEAKICAgICAgICBSRVRWQUw9JD8KICAgICAgICA7OwogICopCiAgICAgICAgZWNobyAkIlVzYWdlOiAkcHJvZyB7c3RhcnR8c3RvcHxyZXN0YXJ0fGNvbmRyZXN0YXJ0fHJlbG9hZHxzdGF0dXMiCiAgICAgICAgZWNobyAkInxmdWxsc3RhdHVzfGdyYWNlZnVsfGhlbHB8Y29uZmlndGVzdH0iCiAgICAgICAgZXhpdCAxCmVzYWMKIApleGl0ICRSRVRWQUw="

if [ "$INSTALL_TYPE" == "INSTALL" ]; then
	echo "[*] INSTALL Mode - Removing package httpd"
	yum -y remove httpd
	
	echo "[*] Updating Apache configuration username/group"
	sed -i 's/^User daemon.*/User apache/' $APACHE_CONF_LOCATION
	sed -i 's/^Group daemon.*/Group apache/' $APACHE_CONF_LOCATION

	grep -q "<IfModule php5_module>" $APACHE_CONF_LOCATION

	if (($? > 0)); then
		echo "[*] Adding PHP5 registration"
		sed -i 's/^LoadModule php5_module        modules\/libphp5.so.*/LoadModule php5_module        modules\/libphp5.so\r\n\r\n\<IfModule php5_module\>\r\n\tAddType application\/x-httpd-php .php\r\n\tAddType application\/x-httpd-php .phps\r\n\t\<IfModule dir_module\>\r\n\t\tDirectoryIndex index.html index.php\r\n\t\<\/IfModule\>\r\n\<\/IfModule\>/' $APACHE_CONF_LOCATION
	fi

	echo "[*] Enabling Apache modules"
	sed -i 's/^#LoadModule file_cache_module modules\/mod_file_cache.so.*/LoadModule file_cache_module modules\/mod_file_cache.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#LoadModule cache_module modules\/mod_cache.so.*/LoadModule cache_module modules\/mod_cache.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#LoadModule cache_disk_module modules\/mod_cache_disk.so.*/LoadModule cache_disk_module modules\/mod_cache_disk.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#LoadModule expires_module modules\/mod_expires.so.*/LoadModule expires_module modules\/mod_expires.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#LoadModule rewrite_module modules\/mod_rewrite.so.*/LoadModule rewrite_module modules\/mod_rewrite.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#LoadModule deflate_module modules\/mod_deflate.so.*/LoadModule deflate_module modules\/mod_deflate.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so.*/LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so/' $APACHE_CONF_LOCATION
	sed -i 's/^#Include conf\/extra\/httpd-ssl.conf.*/Include conf\/extra\/httpd-ssl.conf/' $APACHE_CONF_LOCATION

	echo "[*] Configuring Apache SSL cipher suite and secure options"
	sed -i 's/^SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5.*/#SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5\r\n\r\nSSLProtocol +TLSv1.2 +TLSv1.1 +TLSv1 -SSLv2 -SSLv3\r\nSSLCompression off\r\nSSLHonorCipherOrder on\r\nSSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDH-ECDSA-AES256-GCM-SHA384:AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDH-ECDSA-AES128-GCM-SHA256:AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:DHE-DSS-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:DES-CBC3-SHA/' $APACHE_SSL_CONF_LOCATION
	
	echo "[*] Generating self-signed certificate"
	/opt/openssl-$OPENSSL_VERSION/bin/openssl req -new -newkey rsa:$CSR_KEY_SIZE -nodes -out /usr/local/apache2/conf/server.csr -keyout /usr/local/apache2/conf/server.key -subj "/C=$CSR_COUNTRY/ST=$CSR_STATE/L=$CSR_CITY/O=$CSR_ORGANIZATION/OU=$CSR_DEPARTMENT/CN=$CSR_COMMON_NAME"
	/opt/openssl-$OPENSSL_VERSION/bin/openssl x509 -req -days 365 -in /usr/local/apache2/conf/server.csr -signkey /usr/local/apache2/conf/server.key -out /usr/local/apache2/conf/server.crt

	echo "[*] Installing Apache service"
	echo $INIT_FILE | base64 --decode > /etc/init.d/httpd
	chmod 755 /etc/init.d/httpd
	chkconfig --add httpd
	chkconfig --level 2345 httpd on
fi

echo "[*] Starting Apache"
service httpd start

# Remove build directory and contents
cd
rm -rf $BUILD_DIRECTORY
