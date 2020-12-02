#!/bin/bash

APNAME=${APPNAME:-snipe-it}

MYSQL_VERSION=${MYSQL_VERSION:-mariadb:10.5.8}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: app-${APPNAME}
  labels:
    app: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - image: ${MYSQL_VERSION}
          name: mysql
          imagePullPolicy: IfNotPresent
          ports:
            - name: mysql
              containerPort: 3306
              protocol: TCP
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
          envFrom:
            - configMapRef:
                name: env
          volumeMounts:
            - mountPath: "/var/lib/mysql"
              name: data
              subPath: mysql
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy mysql
	;;
*)
	echo $(basename $0) on/off
	;;
esac
