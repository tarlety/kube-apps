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
  MARIADB_MASTER_HOST: "mariadb"
  MARIADB_MASTER_PORT_NUMBER: "3306"
  MARIADB_MASTER_ROOT_USER: "root"
  MARIADB_REPLICATION_USER: "replicator"
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
