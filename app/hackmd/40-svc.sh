#!/bin/bash

APPNAME=${APPNAME:-hackmd}

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
      port: 3000
      protocol: TCP
  selector:
    app: hackmd
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: app-${APPNAME}
spec:
  ports:
    - name: postgres
      port: 5432
      protocol: TCP
  selector:
    app: postgres
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} svc web
	kubectl delete -n app-${APPNAME} svc postgres
	;;
*)
	echo $(basename $0) on/off
	;;
esac
