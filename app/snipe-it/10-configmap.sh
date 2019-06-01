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
  APP_ENV: "production"
  APP_DEBUG: "false"
  APP_URL: "https://snipe-it.${DOMAIN}"
  APP_TIMEZONE: "Asia/Taipei"
  APP_LOCALE: "zh-TW"
  MYSQL_DATABASE: "snipeit"
  MYSQL_USER: "snipeit"
  MYSQL_PORT_3306_TCP_ADDR: "mysql"
  MAIL_DRIVER: "smtp"
  MAIL_HOST: "smtp"
  MAIL_PORT: "25"
  MAIL_USERNAME: "snipeit"
  MAIL_PASSWORD: ""
  MAIL_ENCRYPTION: "null"
  MAIL_FROM_ADDR: "snipeit@localhost"
  MAIL_FROM_NAME: "Snipe-IT"
  MAIL_REPLYTO_ADDR: "snipeit@localhost"
  MAIL_REPLYTO_NAME: "Snipe-IT"
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap env
	;;
*)
	echo $(basename $0) on/off
	;;
esac
