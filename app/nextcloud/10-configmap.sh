#!/bin/bash

APPNAME=${APPNAME:-nextcloud}

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
  MYSQL_HOST: "mariadb"
  MYSQL_DATABASE: "nextcloud"
  MYSQL_USER: "nextcloud"
  NEXTCLOUD_DATA_DIR: "/var/www/html/data"
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
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap nextcloud-env
	kubectl delete -n app-${APPNAME} configmap mysql-env
	;;
*)
	echo $(basename $0) on/off
	;;
esac
