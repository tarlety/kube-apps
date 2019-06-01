#!/bin/bash

APPNAME=${APPNAME:-snipe-it}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: app-${APPNAME}
  labels:
    app: snipe-it
spec:
  ports:
    - name: web
      port: 80
      protocol: TCP
  selector:
    app: snipe-it
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: app-${APPNAME}
spec:
  ports:
    - name: mysql
      port: 3306
      protocol: TCP
  selector:
    app: mysql
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} svc web
	kubectl delete -n app-${APPNAME} svc mysql
	;;
*)
	echo $(basename $0) on/off
	;;
esac
