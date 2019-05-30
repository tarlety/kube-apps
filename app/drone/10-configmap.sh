#!/bin/bash

ACTION=$1
case $ACTION in
	"on")
		cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: drone-env
  namespace: app-drone
data:
  DRONE_RPC_SECRET: "$(openssl rand -hex 16)"
  DRONE_KUBERNETES_ENABLED: "true"
  DRONE_KUBERNETES_NAMESPACE: "app-drone"
  DRONE_GITEA_SERVER: "http://web.app-gitea:3000"
  DRONE_SERVER_HOST: "drone.${DOMAIN}"
  DRONE_SERVER_PROTO: "https"
EOF
		;;
	"off")
		kubectl delete -n app-drone configmap drone-env
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
