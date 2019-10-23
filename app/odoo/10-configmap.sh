#!/bin/bash

APPNAME=${APPNAME:-odoo}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APPNAME}-env
  namespace: app-${APPNAME}
data:
  HOST: "postgres"
  PORT: "5432"
  USER: "odoo"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-env
  namespace: app-${APPNAME}
data:
  POSTGRES_DB: "postgres"
  POSTGRES_USER: "odoo"
  PGDATA: "/var/lib/postgresql/data/pgdata"
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap ${APPNAME}-env
	kubectl delete -n app-${APPNAME} configmap postgres-env
	;;
*)
	echo $(basename $0) on/off
	;;
esac
