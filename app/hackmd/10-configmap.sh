#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-env
  namespace: app-hackmd
data:
  POSTGRES_DB: "hackmd"
  POSTGRES_USER: "hackmd"
  PGDATA: "/var/lib/postgresql/data/pgdata"
EOF
	;;
	"off")
		kubectl delete -n app-hackmd configmap postgres-env
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
