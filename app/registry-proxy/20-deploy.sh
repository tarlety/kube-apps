#!/bin/bash

APPNAME=${APPNAME:-registry-proxy}

REGISTRY_VERSION=${REGISTRY_VERSION:-registry:2}

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry-proxy
  namespace: app-${APPNAME}
spec:
  selector:
    matchLabels:
      app: registry-proxy
  template:
    metadata:
      labels:
        app: registry-proxy
    spec:
      containers:
        - image: ${REGISTRY_VERSION}
          name: registry-proxy
          imagePullPolicy: IfNotPresent
          env:
            - name: REGISTRY_AUTH
              value: "none"
          ports:
            - name: web
              containerPort: 5000
              protocol: TCP
          volumeMounts:
            - mountPath: "/var/lib/registry"
              name: data
              subPath: registry
            - mountPath: "/backup"
              name: backup
            - mountPath: "/etc/docker/registry/config.yml"
              name: config
              subPath: config.yml
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
      - name: backup
        persistentVolumeClaim:
          claimName: cold
      - name: config
        configMap:
          name: registry-proxy-conf
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy registry-proxy
	;;
*)
	echo $(basename $0) on/off
	;;
esac
