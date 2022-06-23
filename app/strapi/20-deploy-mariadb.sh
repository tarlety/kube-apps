#!/bin/bash

APPNAME=${APPNAME:-strapi}

MARIADB_VERSION=${MARIADB_VERSION:-mariadb:10.8.3}
MARIADB_EXPORTER_VERSION=${MARIADB_EXPORTER_VERSION:-prom/mysqld-exporter:v0.14.0}

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
    type: app
    app: mariadb
    replication: master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
      replication: master
  template:
    metadata:
      labels:
        type: app
        app: mariadb
        replication: master
    spec:
      containers:
        - image: ${MARIADB_VERSION}
          name: mariadb
          imagePullPolicy: IfNotPresent
          args: ["--innodb-buffer-pool-size=1G", "--innodb_io_capacity=4000", "--innodb-read-only-compressed=OFF"]
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
	kubectl delete -n app-${APPNAME} deploy mariadb-master
	;;
*)
	echo $(basename $0) on/off
	;;
esac
