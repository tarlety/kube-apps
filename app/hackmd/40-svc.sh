#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: app-hackmd
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
  namespace: app-hackmd
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
		kubectl delete -n app-hackmd svc web
		kubectl delete -n app-hackmd svc postgres
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
