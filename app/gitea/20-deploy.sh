#!/bin/bash

APPNAME=${APPNAME:-gitea}

GITEA_VERSION=${GITEA_VERSION:-gitea/gitea:1.11.4}
POSTGRES_VERSION=${POSTGRES_VERSION:-postgres:11.2}
POSTGRES_EXPORTOR_VERSION=${POSTGRES_EXPORTOR_VERSION:-wrouesnel/postgres_exporter:v0.4.7}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  namespace: app-${APPNAME}
  labels:
    type: app
    app: gitea
spec:
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        type: app
        app: gitea
    spec:
      containers:
        - image: ${GITEA_VERSION}
          name: gitea
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: gitea-env
          env:
            - name: DB_PASSWD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          ports:
            - name: ssh
              containerPort: 22
              protocol: TCP
            - name: web
              containerPort: 3000
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: web
            initialDelaySeconds: 30
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
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
---
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
            - mountPath: "/backup"
              name: backup
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
              value: postgres://gitea:\$(POSTGRES_PASSWORD)@localhost:5432/postgres?sslmode=disable
          ports:
            - name: exporter
              containerPort: 9187
              protocol: TCP
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
	kubectl delete -n app-${APPNAME} deploy gitea
	kubectl delete -n app-${APPNAME} deploy postgres
	;;
*)
	echo $(basename $0) on/off
	;;
esac
