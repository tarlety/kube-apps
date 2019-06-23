#!/bin/bash

APPNAME=${APPNAME:-nextcloud}

NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION:-nextcloud:16.0.1}
REDIS_VERSION=${REDIS_VERSION:-redis:5.0.5}
MARIADB_VERSION=${MARIADB_VERSION:-mariadb:10.3.15}
MARIADB_EXPORTER_VERSION=${MARIADB_EXPORTER_VERSION:-prom/mysqld-exporter:v0.11.0}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextcloud
  namespace: app-${APPNAME}
  labels:
    app: nextcloud
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nextcloud
  template:
    metadata:
      labels:
        app: nextcloud
    spec:
      containers:
        - image: ${NEXTCLOUD_VERSION}
          name: nextcloud
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: nextcloud-env
          env:
            - name: NEXTCLOUD_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          ports:
            - name: web
              containerPort: 80
              protocol: TCP
          volumeMounts:
            - mountPath: /var/www/html/data
              name: data
              subPath: data
            - mountPath: /var/www/html
              name: data
              subPath: root
            - mountPath: /var/www/html/config
              name: data
              subPath: config
            - mountPath: /var/www/html/custom_apps
              name: data
              subPath: custom_apps
            - mountPath: /var/www/html/themes
              name: data
              subPath: themes
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: app-${APPNAME}
  labels:
    app: redis
spec:
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - image: ${REDIS_VERSION}
          name: redis
          imagePullPolicy: IfNotPresent
          args: ["--requirepass", "\$(REDIS_PASSWORD)"]
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
            - mountPath: /var/lib/redis
              name: data
              subPath: redis
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: app-${APPNAME}
  labels:
    app: mariadb
spec:
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
        - image: ${MARIADB_VERSION}
          name: mariadb
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: mysql-env
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          ports:
            - name: mysql
              containerPort: 3306
              protocol: TCP
          volumeMounts:
            - mountPath: /var/lib/mysql
              name: data
              subPath: mysql
            - mountPath: /var/lib/backup
              name: backup
        - image: ${MARIADB_EXPORTER_VERSION}
          name: exporter
          imagePullPolicy: IfNotPresent
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: DATA_SOURCE_NAME
              value: "root:\$(MYSQL_ROOT_PASSWORD)@(localhost:3306)/"
          ports:
            - name: exporter
              containerPort: 9104
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
	kubectl delete -n app-${APPNAME} deploy nextcloud
	kubectl delete -n app-${APPNAME} deploy redis
	kubectl delete -n app-${APPNAME} deploy mariadb
	;;
*)
	echo $(basename $0) on/off
	;;
esac
