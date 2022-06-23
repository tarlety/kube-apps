#!/bin/bash

APPNAME=${APPNAME:-strapi}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: app-${APPNAME}
spec:
  ports:
    - name: web
      port: 1337
      protocol: TCP
  selector:
    app: strapi
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb
  namespace: app-${APPNAME}
spec:
  ports:
    - name: mysql
      port: 3306
      protocol: TCP
  selector:
    app: mariadb
    replication: master
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} svc web
	kubectl delete -n app-${APPNAME} svc mariadb
	;;
*)
	echo $(basename $0) on/off
	;;
esac
