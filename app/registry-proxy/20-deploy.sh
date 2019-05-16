#!/bin/bash

REGISTRY_VERSION=${REGISTRY_VERSION:-registry:2}
REGISTRY_UI_VERSION=${REGISTRY_UI_VERSION:-hyper/docker-registry-web:v0.1.2}

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry-proxy
  namespace: app-registry-proxy
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
            - name: registry
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
        - image: ${REGISTRY_UI_VERSION}
          name: registry-proxy-ui
          imagePullPolicy: IfNotPresent
          env:
            - name: REGISTRY_URL
              value: "http://localhost:5000/v2"
            - name: REGISTRY_NAME
              value: "zerus registry proxy"
            - name: REGISTRY_AUTH_ENABLED
              value: "false"
          ports:
            - name: web
              containerPort: 8080
              protocol: TCP
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
		kubectl delete -n app-registry-proxy deploy registry-proxy
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
