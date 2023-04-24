#!/bin/bash

APPNAME=${APPNAME:-hackmd}

#POSTGRES_VERSION=${POSTGRES_VERSION:-postgres:11.2}
# The reason to keep postgres 9.6:
# 1. The data directory was initialized by PostgreSQL version 9.6, which is not compatible with this version 11.
# 2. postgres 9.6 End of Life: 2021-09
POSTGRES_VERSION=${POSTGRES_VERSION:-postgres:9.6.18}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: app-${APPNAME}
  labels:
    type: app
    app: postgres
spec:
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        type: app
        app: postgres
    spec:
      containers:
        - image: ${POSTGRES_VERSION}
          name: postgres
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: postgres-env
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          ports:
            - name: postgres
              containerPort: 5432
              protocol: TCP
          livenessProbe:
            initialDelaySeconds: 30
            tcpSocket:
              port: postgres
            timeoutSeconds: 1
          volumeMounts:
            - mountPath: "/var/lib/postgresql/data/pgdata"
              name: data
              subPath: pgdata
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy postgres
	;;
*)
	echo "$(basename $0) on/off"
	;;
esac
