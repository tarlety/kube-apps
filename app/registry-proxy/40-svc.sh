#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: app-registry-proxy
spec:
  ports:
    - name: web
      port: 5000
      protocol: TCP
  selector:
    app: registry-proxy
EOF
		;;
	"off")
		kubectl delete -n app-registry-proxy svc web
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
