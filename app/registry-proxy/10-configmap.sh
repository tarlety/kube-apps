#!/bin/bash

APPNAME=${APPNAME:-registry-proxy}

ACTION=$1
case $ACTION in
"on")
	kubectl create -n app-${APPNAME} configmap config --from-file=config.yml=$(dirname $0)/config.yml
	;;
"off")
	kubectl delete -n app-${APPNAME} configmap config
	;;
*)
	echo $(basename $0) on/off
	;;
esac
