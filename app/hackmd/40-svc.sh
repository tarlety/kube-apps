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
  name: postgres13
  namespace: app-${APPNAME}
spec:
  ports:
    - name: postgres13
      port: 5432
      protocol: TCP
  selector:
    database: postgres13
---
apiVersion: v1
kind: Service
metadata:
  name: postgres9
  namespace: app-${APPNAME}
spec:
  ports:
    - name: postgres9
      port: 5433
      protocol: TCP
  selector:
    database: postgres9
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} svc web
	kubectl delete -n app-${APPNAME} svc postgres9 postgres13
	;;
*)
	echo $(basename $0) on/off
	;;
esac
