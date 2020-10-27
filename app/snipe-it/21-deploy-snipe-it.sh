#!/bin/bash

APNAME=${APPNAME:-snipe-it}

SNIPEIT_VERSION=${SNIPEIT_VERSION:-snipe/snipe-it:v5.0.1}
# https://hub.docker.com/_/alpine
ALPINE_VERSION=${ALPINE_VERSION:-alpine:3.12.0}

ACTION=$1
case $ACTION in
"on")
    cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: snipe-it
  namespace: app-${APPNAME}
spec:
  selector:
    matchLabels:
      app: snipe-it
  template:
    metadata:
      labels:
        app: snipe-it
    spec:
      initContainers:
        - name: config-data
          image: busybox
          command: ["chown","-R","1000", "/var/www/html/storage/framework/sessions"]
          volumeMounts:
            - name: data
              mountPath: /var/www/html/storage/framework/sessions
              subPath: sessions
      containers:
        - image: ${SNIPEIT_VERSION}
          name: snipe-it
          imagePullPolicy: IfNotPresent
          ports:
            - name: web
              containerPort: 3000
              protocol: TCP
          env:
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          envFrom:
            - configMapRef:
                name: env
            - secretRef:
                name: ${APPNAME}-secret
          volumeMounts:
            - mountPath: "/var/log/apache2"
              name: data
              subPath: apache2
            - mountPath: "/var/lib/snipeit"
              name: data
              subPath: snipeit
            - mountPath: "/backup"
              name: backup
            - mountPath: /var/www/html/storage/framework/sessions
              name: data
              subPath: sessions
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
    kubectl delete -n app-${APPNAME} deploy snipe-it
    ;;
*)
    echo $(basename $0) on/off
    ;;
esac
