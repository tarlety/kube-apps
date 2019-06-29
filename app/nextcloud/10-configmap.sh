#!/bin/bash

APPNAME=${APPNAME:-nextcloud}
DOMAIN=${DOMAIN:-minikube}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nextcloud-env
  namespace: app-${APPNAME}
data:
  NEXTCLOUD_ADMIN_USER: "admin"
  REDIS_HOST: "redis"
  MYSQL_HOST: "mariadb"
  MYSQL_DATABASE: "nextcloud"
  MYSQL_USER: "nextcloud"
  NEXTCLOUD_DATA_DIR: "/var/www/html/data"
  NEXTCLOUD_TRUSTED_DOMAINS: "${APPNAME}.${DOMAIN}"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-env
  namespace: app-${APPNAME}
data:
  MYSQL_DATABASE: "nextcloud"
  MYSQL_USER: "nextcloud"
EOF

	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: app-${APPNAME}
data:
  nginx.conf: |
    upstream php-handler {
        server 127.0.0.1:9000;
        #server unix:/var/run/php/php7.0-fpm.sock;
    }

    server {
        listen 80;
        listen [::]:80;
        server_name ${APPNAME}.${DOMAIN};
        # enforce https
        #return 301 https://$server_name$request_uri;
        #listen 443 ssl http2;
        #listen [::]:443 ssl http2;
        #server_name cloud.example.com;

        # Use Mozilla's guidelines for SSL/TLS settings
        # https://mozilla.github.io/server-side-tls/ssl-config-generator/
        # NOTE: some settings below might be redundant
        #ssl_certificate /etc/ssl/nginx/cloud.example.com.crt;
        #ssl_certificate_key /etc/ssl/nginx/cloud.example.com.key;

        # Add headers to serve security related headers
        # Before enabling Strict-Transport-Security headers please read into this
        # topic first.
        # add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;

        # Remove X-Powered-By, which is an information leak
        fastcgi_hide_header X-Powered-By;

        # Path to the root of your installation
        root /var/www/html/;

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        }

        # The following 2 rules are only needed for the user_webfinger app.
        # Uncomment it if you're planning to use this app.
        #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
        #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json last;

        # The following rule is only needed for the Social app.
        # Uncomment it if you're planning to use this app.
        # rewrite ^/.well-known/webfinger /public.php?service=webfinger last;

        location = /.well-known/carddav {
          return 301 \$scheme://\$host/remote.php/dav;
        }
        location = /.well-known/caldav {
          return 301 \$scheme://\$host/remote.php/dav;
        }

        # set max upload size
        client_max_body_size 512M;
        fastcgi_buffers 64 4K;

        # Enable gzip but do not remove ETag headers
        gzip on;
        gzip_vary on;
        gzip_comp_level 4;
        gzip_min_length 256;
        gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
        gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

        # Uncomment if your server is build with the ngx_pagespeed module
        # This module is currently not supported.
        #pagespeed off;

        location / {
            rewrite ^ /index.php\$request_uri;
        }

        location ~ ^\\/(?:build|tests|config|lib|3rdparty|templates|data)\\/ {
            deny all;
        }
        location ~ ^\\/(?:\\.|autotest|occ|issue|indie|db_|console) {
            deny all;
        }

        location ~ ^\\/(?:index|remote|public|cron|core\\/ajax\\/update|status|ocs\\/v[12]|updater\\/.+|oc[ms]-provider\\/.+)\\.php(?:$|\\/) {
            fastcgi_split_path_info ^(.+?\\.php)(\\/.*|)$;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
            fastcgi_param HTTPS on;
            #Avoid sending the security headers twice
            fastcgi_param modHeadersAvailable true;
            fastcgi_param front_controller_active true;
            fastcgi_pass php-handler;
            fastcgi_intercept_errors on;
            fastcgi_request_buffering off;
            fastcgi_read_timeout 3600;
        }

        location ~ ^\\/(?:updater|oc[ms]-provider)(?:$|\\/) {
            try_files \$uri/ =404;
            index index.php;
        }

        # Adding the cache control header for js, css and map files
        # Make sure it is BELOW the PHP block
        location ~ \\.(?:css|js|woff2?|svg|gif|map)$ {
            try_files \$uri /index.php\$request_uri;
            add_header Cache-Control "public, max-age=15778463";
            # Add headers to serve security related headers (It is intended to
            # have those duplicated to the ones above)
            # Before enabling Strict-Transport-Security headers please read into
            # this topic first.
            # add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
            #
            # WARNING: Only add the preload option once you read about
            # the consequences in https://hstspreload.org/. This option
            # will add the domain to a hardcoded list that is shipped
            # in all major browsers and getting removed from this list
            # could take several months.
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Robots-Tag none;
            add_header X-Download-Options noopen;
            add_header X-Permitted-Cross-Domain-Policies none;
            add_header Referrer-Policy no-referrer;

            # Optional: Don't log access to assets
            access_log off;
        }

        location ~ \\.(?:png|html|ttf|ico|jpg|jpeg)$ {
            try_files \$uri /index.php\$request_uri;
            # Optional: Don't log access to other assets
            access_log off;
        }
    }
EOF

	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: userini-conf
  namespace: app-${APPNAME}
data:
  .user.ini: |
    mbstring.func_overload=0
    always_populate_raw_post_data=-1
    default_charset='UTF-8'
    output_buffering=0
    zend_extension=opcache.so
    opcache.enable=1
    opcache.enable_cli=1
    opcache.huge_code_pages=1
    opcache.file_cache=/tmp
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap nextcloud-env mysql-env
	kubectl delete -n app-${APPNAME} configmap nginx-conf userini-conf
	;;
*)
	echo $(basename $0) on/off
	;;
esac
