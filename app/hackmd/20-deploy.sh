#!/bin/bash

HACKMD_VERSION=${HACKMD_VERSION:-hackmdio/hackmd:1.3.1}
POSTGRES_VERSION=${POSTGRES_VERSION:-postgres:11.2}
POSTGRES_EXPORTOR_VERSION=${POSTGRES_EXPORTOR_VERSION:-wrouesnel/postgres_exporter:v0.4.7}

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hackmd
  namespace: app-hackmd
spec:
  selector:
    matchLabels:
      app: hackmd
  template:
    metadata:
      labels:
        app: hackmd
    spec:
      containers:
        - image: ${HACKMD_VERSION}
          name: hackmd
          imagePullPolicy: IfNotPresent
          env:
            - name: HMD_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
            - name: HMD_DB_URL
              value: postgres://hackmd:\$(HMD_DB_PASSWORD)@postgres:5432/hackmd
          ports:
            - name: web
              containerPort: 3000
              protocol: TCP
          livenessProbe:
            initialDelaySeconds: 30
            tcpSocket:
              port: web
            timeoutSeconds: 1
          volumeMounts:
            - mountPath: "/hackmd/public/uploads"
              name: data
              subPath: uploads
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: normal
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: app-hackmd
  labels:
    app: postgres
spec:
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
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
            - name: postgresql
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
        - image: ${POSTGRES_EXPORTOR_VERSION}
          name: exporter
          imagePullPolicy: IfNotPresent
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
            - name: DATA_SOURCE_NAME
              value: postgres://hackmd:\$(POSTGRES_PASSWORD)@localhost:5432/postgres?sslmode=disable
          ports:
            - name: exporter
              containerPort: 9187
              protocol: TCP
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
EOF
	;;
	"off")
		kubectl delete -n app-hackmd deploy hackmd
		kubectl delete -n app-hackmd deploy postgres
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
