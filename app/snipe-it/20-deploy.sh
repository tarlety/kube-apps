#!/bin/bash

SNIPEIT_VERSION=${SNIPEIT_VERSION:-snipe/snipe-it:v4.6.6}
MYSQL_VERSION=${MYSQL_VERSION:-mysql:5.7.24}

ACTION=$1
case $ACTION in
	"on")
cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: snipe-it
  namespace: app-snipe-it
spec:
  selector:
    matchLabels:
      app: snipe-it
  template:
    metadata:
      labels:
        app: snipe-it
    spec:
      containers:
        - image: ${SNIPEIT_VERSION}
          name: snipe-it
          imagePullPolicy: IfNotPresent
          ports:
            - name: web
              containerPort: 3000
              protocol: TCP
          env:
            - name: APP_KEY
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: admin-password
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
            - name: MAIL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: rest-password
          envFrom:
            - configMapRef:
                name: env
          volumeMounts:
            - mountPath: "/var/log/apache2"
              name: log
            - mountPath: "/var/lib/snipeit"
              name: data
      volumes:
        - name: log
          emptyDir: {}
        - name: data
          emptyDir: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: app-snipe-it
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
            - name: MYSQL_RANDOM_ROOT_PASSWORD
              value: "true"
            - name: MYSQL_ONETIME_PASSWORD
              value: "true"
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
              name: mysql
      volumes:
      - name: mysql
        emptyDir: {}
EOF
	;;
	"off")
		kubectl delete -n app-snipe-it deploy snipe-it
		kubectl delete -n app-snipe-it deploy mysql
		;;
	*)
		echo $(basename $0) on/off
		;;
esac
