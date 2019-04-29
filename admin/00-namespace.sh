#!/bin/bash

APPNAME=$1
ACTION=$2

case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Namespace
metadata:
  name: app-${APPNAME}
EOF
	;;
	"off")
		kubectl delete namespace app-${APPNAME}
		;;
	*)
		echo $(basename $0) appname on/off
		;;
esac
