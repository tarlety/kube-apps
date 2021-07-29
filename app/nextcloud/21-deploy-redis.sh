#!/bin/bash

APPNAME=${APPNAME:-nextcloud}

REDIS_VERSION=${REDIS_VERSION:-redis:6.2.5}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: app-${APPNAME}
  labels:
    type: app
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        type: app
        app: redis
    spec:
      containers:
        - image: ${REDIS_VERSION}
          name: redis
          imagePullPolicy: IfNotPresent
          env:
            - name: REDIS_DATABASES
              value: "1"
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: rest-password
          ports:
            - name: redis
              containerPort: 6379
              protocol: TCP
          volumeMounts:
            - mountPath: /data
              name: data
              subPath: redis
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy redis
	;;
*)
	echo $(basename $0) on/off
	;;
esac
