#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: owncloud-env
  namespace: app-owncloud
data:
  OWNCLOUD_ADMIN_USERNAME: "admin"
  OWNCLOUD_DB_TYPE: "mysql"
  OWNCLOUD_DB_HOST: "mariadb"
  OWNCLOUD_DB_NAME: "owncloud"
  OWNCLOUD_DB_USERNAME: "owncloud"
  OWNCLOUD_MYSQL_UTF8MB4: "true"
  OWNCLOUD_REDIS_ENABLED: "true"
  OWNCLOUD_REDIS_HOST: "redis"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-env
  namespace: app-owncloud
data:
  MYSQL_DATABASE: "owncloud"
  MYSQL_USER: "owncloud"
EOF
	;;
	"off")
		kubectl delete -n app-owncloud configmap owncloud-env
		kubectl delete -n app-owncloud configmap mysql-env
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
