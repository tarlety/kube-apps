#!/bin/bash

APPNAME=${APPNAME:-hackmd}

POSTGRES_VERSION13=${POSTGRES_VERSION:-postgres:13.13}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
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
	kubectl delete -n app-${APPNAME} deploy postgres13
	;;
*)
	echo "$(basename $0) on/off"
	;;
esac
