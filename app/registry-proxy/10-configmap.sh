#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
		kubectl create configmap registry-proxy-conf -n app-registry-proxy --from-file=config.yml=$(dirname $0)/config.yml
		;;
	"off")
		kubectl delete configmap registry-proxy-conf -n app-registry-proxy
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
