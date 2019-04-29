#!/bin/bash

NODE_SSH_PORT=${NODE_SSH_PORT:-22}
echo NODE_SSH_PORT=$NODE_SSH_PORT

DB_TYPE=${DB_TYPE:-postgres}
echo DB_TYPE=$DB_TYPE

ACTION=$1
case $ACTION in
	"on")
		if [ ${DB_TYPE} == "sqlite3" ]; then
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitea-env
  namespace: app-gitea
data:
  RUN_MODE: "prod"
  SSH_DOMAIN: "gitea.${DOMAIN}"
  SSH_PORT: "${NODE_SSH_PORT}"
  ROOT_URL: "https://gitea.${DOMAIN}"
EOF
		fi
		if [ ${DB_TYPE} == "postgres" ]; then
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitea-env
  namespace: app-gitea
data:
  RUN_MODE: "prod"
  SSH_DOMAIN: "gitea.${DOMAIN}"
  SSH_PORT: "${NODE_SSH_PORT}"
  ROOT_URL: "https://gitea.${DOMAIN}"
  DB_TYPE: "postgres"
  DB_HOST: "postgres:5432"
  DB_NAME: "gitea"
  DB_USER: "gitea"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-env
  namespace: app-gitea
data:
  POSTGRES_DB: "gitea"
  POSTGRES_USER: "gitea"
  PGDATA: "/var/lib/postgresql/data/pgdata"
EOF
		fi
	;;
	"off")
		kubectl delete -n app-gitea configmap gitea-env
		kubectl delete -n app-gitea configmap postgres-env
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
