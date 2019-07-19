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
    app: collabora
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} svc web
	;;
*)
	echo $(basename $0) on/off
	;;
esac
