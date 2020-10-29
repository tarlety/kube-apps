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
    app: ${APPNAME}
spec:
  ports:
    - name: web
      port: 80
      protocol: TCP
  selector:
    app: ${APPNAME}
---
apiVersion: v1
kind: Service
metadata:
  name: snipe-it
  namespace: app-${APPNAME}
  labels:
    app: ${APPNAME}
spec:
  ports:
    - name: snipe-it
      port: 80
      protocol: TCP
  selector:
    app: ${APPNAME}
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
	kubectl delete -n app-${APPNAME} svc web snipe-it mysql
	;;
*)
	echo $(basename $0) on/off
	;;
esac
