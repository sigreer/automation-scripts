#!/bin/bash

NGINX_VERSION=1.21.3
PCRE=pcre-8.45
ZLIB=zlib-1.2.11
HEADERS_MORE=v0.33
NPS_VERSION=1.13.35.2-stable
NPS_RELEASE_NUMBER=${NPS_VERSION/stable/}
nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d)
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz
apt update
apt upgrade -y
apt-get install checkinstall libpcre3 libpcre3-dev zlib1g zlib1g-dbg zlib1g-dev curl gnupg2 ca-certificates lsb-release build-essential  unzip uuid-dev software-properties-common gnupg2
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
add-apt-repository "deb [arch=amd64] http://mariadb.mirror.liquidtelecom.com/repo/10.5/debian $(lsb_release -cs) main"
apt update
apt upgrade -y
apt install mariadb-server mariadb-client -y
#echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" \
#    | sudo tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
wget https://ftp.pcre.org/pub/pcre/${PCRE}.tar.bz2
wget http://zlib.net/${ZLIB}.tar.gz
wget https://github.com/openresty/headers-more-nginx-module/archive/${HEADERS_MORE}.tar.gz
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
git clone https://github.com/arut/nginx-rtmp-module
wget -O- https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.tar.gz | tar -xz
cd "$nps_dir"
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget -O- ${psol_url} | tar -xz
cd ../
tar -xvf nginx-${NGINX_VERSION}.tar.gz
tar -xvf v0.33.tar.gz
tar -xvf ${PCRE}.tar.bz2
tar -xvf ${ZLIB}.tar.gz
#tar -xvf openssl-1.1.1.tar.gz
cd nginx-${NGINX_VERSION}
./configure --prefix=/etc/nginx\
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=www-data \
--group=www-data \
--with-compat \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-pcre=../${PCRE} \
--with-zlib=../${ZLIB} \
--with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-${NGINX_VERSION}/debian/debuild-base/nginx-${NGINX_VERSION}=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
--with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie'
make
make install
mkdir -p /var/cache/nginx/client_temp
systemctl stop apache2
systemctl disable apache2
mkdir /var/log/nginx
mkdir /var/cache/nginx && chown www-data:www-data /var/cache/nginx
mkdir /etc/nginx/sites-available && mkdir /etc/nginx/sites-enabled
cat <<EOT >> 
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOT

systemctl enable nginx
systemctl start nginx
