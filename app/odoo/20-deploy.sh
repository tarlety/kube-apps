#!/bin/bash

APPNAME=${APPNAME:-odoo}

# https://hub.docker.com/_/odoo
ODOO_VERSION=${ODOO_VERSION:-odoo:15.0}
# https://hub.docker.com/_/postgres
POSTGRES_VERSION=${POSTGRES_VERSION:-postgres:14.1}
# https://hub.docker.com/r/wrouesnel/postgres_exporter
POSTGRES_EXPORTOR_VERSION=${POSTGRES_EXPORTOR_VERSION:-wrouesnel/postgres_exporter:v0.8.0}

ACTION=$1
case $ACTION in
"on")
        cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APPNAME}
  namespace: app-${APPNAME}
  labels:
    type: app
    app: ${APPNAME}
spec:
  selector:
    matchLabels:
      app: ${APPNAME}
  template:
    metadata:
      labels:
        type: app
        app: ${APPNAME}
    spec:
      containers:
        - image: ${ODOO_VERSION}
          name: ${APPNAME}
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: ${APPNAME}-env
          env:
            - name: PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          ports:
            - name: web
              containerPort: 8069
              protocol: TCP
          volumeMounts:
            - mountPath: "/var/lib/odoo"
              name: data
              subPath: odoo
            - mountPath: "/mnt/extra-addons"
              name: data
              subPath: extra-addons
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
          envFrom:
            - configMapRef:
                name: postgres-env
          env:
            - name: DATA_SOURCE_NAME
              value: postgres://\$(POSTGRES_USER):\$(POSTGRES_PASSWORD)@localhost:5432/postgres?sslmode=disable
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
        kubectl delete -n app-${APPNAME} deploy ${APPNAME}
        kubectl delete -n app-${APPNAME} deploy postgres
        ;;
*)
	echo $(basename $0) on/off
	;;
esac
