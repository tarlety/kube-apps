#!/bin/bash

DRONE_VERSION=${DRONE_VERSION:-drone/drone:1.1.0}

ACTION=$1
case $ACTION in
	"on")
		cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: drone
  namespace: app-drone
spec:
  selector:
    matchLabels:
      app: drone
  template:
    metadata:
      labels:
        app: drone
    spec:
      containers:
        - image: ${DRONE_VERSION}
          name: drone
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: drone-env
          ports:
            - name: web
              containerPort: 80
              protocol: TCP
          volumeMounts:
            - mountPath: "/data"
              name: data
              subPath: data
            - mountPath: "/backup"
              name: backup
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
      - name: backup
        persistentVolumeClaim:
          claimName: cold
EOF
		;;
	"off")
		kubectl delete -n app-drone deploy drone
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
