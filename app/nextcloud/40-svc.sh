#!/bin/bash

APPNAME=${APPNAME:-nextcloud}

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
      port: 80
      protocol: TCP
  selector:
    app: nextcloud
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: app-${APPNAME}
spec:
  ports:
    - name: redis
      port: 6379
      protocol: TCP
  selector:
    app: redis
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
    app: mariadb-master
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} svc web
	kubectl delete -n app-${APPNAME} svc redis
	kubectl delete -n app-${APPNAME} svc mariadb
	;;
*)
	echo $(basename $0) on/off
	;;
esac
