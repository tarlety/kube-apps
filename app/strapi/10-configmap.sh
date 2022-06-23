#!/bin/bash

APPNAME=${APPNAME:-strapi}
DOMAIN=${DOMAIN:-minikube}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: strapi-env
  namespace: app-${APPNAME}
data:
  DATABASE_CLIENT: "mysql"
  DATABASE_HOST: "mariadb"
  DATABASE_PORT: "3306"
  DATABASE_NAME: "strapi"
  DATABASE_USERNAME: "strapi"
  DATABASE_SSL: "false"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-env
  namespace: app-${APPNAME}
data:
  MYSQL_DATABASE: "strapi"
  MYSQL_USER: "strapi"
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap strapi-env mysql-env
	;;
*)
	echo $(basename $0) on/off
	;;
esac
