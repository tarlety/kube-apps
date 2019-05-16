#!/bin/bash

NODE_PORTS=${NODE_PORTS:-5000}
NODE_REGISTRY_PORT=$(echo $NODE_PORTS | { read NODE_REGISTRY_PORT NODE_REST_PORTS ; echo $NODE_REGISTRY_PORT ; })

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
      port: 8080
      protocol: TCP
  selector:
    app: registry-proxy
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: app-registry-proxy
spec:
  type: NodePort
  ports:
    - name: registry
      port: 5000
      nodePort: ${NODE_REGISTRY_PORT}
      protocol: TCP
  selector:
    app: registry-proxy
EOF
		;;
	"off")
		kubectl delete -n app-registry-proxy svc registry web
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
