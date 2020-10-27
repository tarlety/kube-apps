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
  APP_TRUSTED_PROXIES: "10.244.0.0/16"

  # Mysql Parameters
  MYSQL_DATABASE: "snipeit"
  MYSQL_HOST: "mysql"
  MYSQL_USER: "snipeit"
  MYSQL_PORT_3306_TCP_ADDR: "mysql"
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap env
	;;
*)
	echo $(basename $0) on/off
	;;
esac
