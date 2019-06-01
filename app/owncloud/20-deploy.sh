#!/bin/bash

APPNAME=${APPNAME:-owncloud}

OWNCLOUD_VERSION=${OWNCLOUD_VERSION:-owncloud/server:10.0.10}
REDIS_VERSION=${REDIS_VERSION:-redis:5.0.3}
MARIADB_VERSION=${MARIADB_VERSION:-mariadb:10.3.11}
MARIADB_EXPORTER_VERSION=${MARIADB_EXPORTER_VERSION:-prom/mysqld-exporter:v0.11.0}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: owncloud
  namespace: app-${APPNAME}
  labels:
    app: owncloud
spec:
  selector:
    matchLabels:
      app: owncloud
  template:
    metadata:
      labels:
        app: owncloud
    spec:
      containers:
        - image: ${OWNCLOUD_VERSION}
          name: owncloud
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: owncloud-env
          env:
            - name: OWNCLOUD_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: OWNCLOUD_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
            - name: OWNCLOUD_REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: rest-password
          ports:
            - name: web
              containerPort: 8080
              protocol: TCP
          volumeMounts:
            - mountPath: /mnt/data
              name: data
              subPath: data
          lifecycle:
            postStart:
              exec:
                command: ["/bin/sh", "-c", "sed -i -e 's/513M/100G/g' /var/www/owncloud/.user.ini ; sed -i -e 's/513M/100G/g' /var/www/owncloud/.htaccess"]
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
	kubectl delete -n app-${APPNAME} deploy owncloud
	kubectl delete -n app-${APPNAME} deploy redis
	kubectl delete -n app-${APPNAME} deploy mariadb
	;;
*)
	echo $(basename $0) on/off
	;;
esac
