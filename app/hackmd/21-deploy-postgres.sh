#!/bin/bash

APPNAME=${APPNAME:-hackmd}

# The reason to keep old data in postgres 9.6:
# 1. The data directory was initialized by PostgreSQL version 9.6, which is not compatible with this version 11.
# 2. postgres 9.6 End of Life: 2021-09
POSTGRES_VERSION9=${POSTGRES_VERSION:-postgres:9.6.18}
POSTGRES_VERSION13=${POSTGRES_VERSION:-postgres:13.11}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres9
  namespace: app-${APPNAME}
  labels:
    type: database
    database: postgres9
spec:
  selector:
    matchLabels:
      database: postgres9
  template:
    metadata:
      labels:
        type: database
        database: postgres9
    spec:
      containers:
        - image: ${POSTGRES_VERSION9}
          name: postgres9
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
            - name: postgres9
              containerPort: 5433
              protocol: TCP
          livenessProbe:
            initialDelaySeconds: 30
            tcpSocket:
              port: postgres
            timeoutSeconds: 1
          volumeMounts:
            - mountPath: "/var/lib/postgresql/data/pgdata"
              name: data
              subPath: pgdata9
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres13
  namespace: app-${APPNAME}
  labels:
    type: database
    database: postgres13
spec:
  selector:
    matchLabels:
      database: postgres13
  template:
    metadata:
      labels:
        type: database
        database: postgres13
    spec:
      containers:
        - image: ${POSTGRES_VERSION13}
          name: postgres13
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
            - name: postgres13
              containerPort: 5432
              protocol: TCP
          volumeMounts:
            - mountPath: "/var/lib/postgresql/data/pgdata"
              name: data
              subPath: pgdata13
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy postgres9 postgres13
	;;
*)
	echo "$(basename $0) on/off"
	;;
esac
