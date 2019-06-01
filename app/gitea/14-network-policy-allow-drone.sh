#!/bin/bash
# for cicd-pipeline, allow specific namespace "app-drone" to access app gitea

APPNAME=${APPNAME:-gitea}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: app-${APPNAME}
  name: allow-app-drone
spec:
  podSelector:
    matchLabels:
      app: gitea
  ingress:
  - ports:
    - port: 3000
  - from:
    - namespaceSelector:
        matchLabels:
          security: cicd-pipeline
    - podSelector:
        matchLabels:
          app: drone
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} networkpolicy allow-app-drone
	;;
*)
	echo $(basename $0) on/off
	;;
esac
