#!/bin/bash

APPNAME=${APPNAME:-nextcloud}

MARIADB_VERSION=${MARIADB_VERSION:-mariadb:10.3.16}
MARIADB_EXPORTER_VERSION=${MARIADB_EXPORTER_VERSION:-prom/mysqld-exporter:v0.11.0}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-master
  namespace: app-${APPNAME}
  labels:
    app: mariadb-master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb-master
  template:
    metadata:
      labels:
        app: mariadb-master
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
            - name: MARIADB_REPLICATION_MODE
              value: "master"
            - name: MARIADB_REPLICATION_PASSWORD
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
              subPath: mysql-master
            - mountPath: /var/lib/backup
              name: backup
              subPath: mysql-master
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-slave-1
  namespace: app-${APPNAME}
  labels:
    app: mariadb-slave
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb-slave
  template:
    metadata:
      labels:
        app: mariadb-slave
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
            - name: MARIADB_REPLICATION_MODE
              value: "slave"
            - name: MARIADB_MASTER_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: MARIADB_REPLICATION_PASSWORD
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
              subPath: mysql-slave-1
            - mountPath: /var/lib/backup
              name: backup
              subPath: "mysql-slave"
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-slave-2
  namespace: app-${APPNAME}
  labels:
    app: mariadb-slave
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb-slave
  template:
    metadata:
      labels:
        app: mariadb-slave
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
            - name: MARIADB_REPLICATION_MODE
              value: "slave"
            - name: MARIADB_MASTER_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: MARIADB_REPLICATION_PASSWORD
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
              subPath: mysql-slave-2
            - mountPath: /var/lib/backup
              name: backup
              subPath: "mysql-slave"
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
	kubectl delete -n app-${APPNAME} deploy mariadb-master mariadb-slave
	;;
*)
	echo $(basename $0) on/off
	;;
esac
