#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: app-owncloud
spec:
  ports:
    - name: web
      port: 8080
      protocol: TCP
  selector:
    app: owncloud
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: app-owncloud
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
  namespace: app-owncloud
spec:
  ports:
    - name: mysql
      port: 3306
      protocol: TCP
  selector:
    app: mariadb
EOF
	;;
	"off")
		kubectl delete -n app-owncloud svc web
		kubectl delete -n app-owncloud svc redis
		kubectl delete -n app-owncloud svc mariadb
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
