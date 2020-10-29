#!/bin/bash

APPNAME=${APPNAME:-snipe-it}
DOMAIN=${DOMAIN:-minikube}

ACTION=$1
case $ACTION in
"on")
    cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: env
  namespace: app-${APPNAME}
data:
  # Snipe-IT Settings
  APP_ENV: "production"
  APP_DEBUG: "false"
  APP_URL: "https://snipe-it.${DOMAIN}"
  APP_TIMEZONE: "Asia/Taipei"
  APP_LOCALE: "zh-TW"
  APP_TRUSTED_PROXIES: "0.0.0.0/0"

  # Mysql Parameters
  MYSQL_DATABASE: "snipeit"
  MYSQL_HOST: "mysql"
  MYSQL_USER: "snipeit"
  MYSQL_PORT_3306_TCP_ADDR: "mysql"
EOF

    cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: app-${APPNAME}
data:
  nginx.conf: |
    server {
        listen 80;
        server_name ${APPNAME}.${DOMAIN};
        location / {
            proxy_pass http://snipe-it;
            proxy_set_header X-Forwarded-Proto https;
        }
    }
EOF
    ;;
"off")
    kubectl delete -n app-${APPNAME} configmap env nginx-conf
    ;;
*)
    echo $(basename $0) on/off
    ;;
esac
