#!/bin/bash

APPNAME=${APPNAME:-odoo}

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
      port: 8069
      protocol: TCP
  selector:
    app: ${APPNAME}
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
