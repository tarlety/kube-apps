#!/bin/bash

APPNAME=${APPNAME:-snipe-it}

SNIPEIT_VERSION=${SNIPEIT_VERSION:-snipe/snipe-it:v5.3.3}
# https://hub.docker.com/_/nginx
NGINX_VERSION=${NGINX_VERSION:-nginx:1.21.4}
# https://hub.docker.com/_/busybox
BUSYBOX_VERSION=${BUSYBOX_VERSION:-busybox:1.34.1}

ACTION=$1
case $ACTION in
"on")
    cat <<EOF | kubectl create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: snipe-it
  namespace: app-${APPNAME}
  labels:
    type: app
    app: snipe-it
spec:
  selector:
    matchLabels:
      app: snipe-it
  template:
    metadata:
      labels:
        type: app
        app: snipe-it
    spec:
      initContainers:
        - name: config-data
          image: ${BUSYBOX_VERSION}
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
            - name: snipe-it
              containerPort: 80
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
            - secretRef:
                name: ${APPNAME}-mail
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: app-${APPNAME}
  labels:
    type: app
    app: nginx
spec:
  selector:
    matchLabels:
      app: snipe-it
  template:
    metadata:
      labels:
        type: app
        app: snipe-it
    spec:
      containers:
        - image: ${NGINX_VERSION}
          name: nginx
          imagePullPolicy: IfNotPresent
          ports:
            - name: web
              containerPort: 80
              protocol: TCP
          volumeMounts:
            - mountPath: /etc/nginx/conf.d
              name: nginx-conf
              readOnly: true
      volumes:
        - name: nginx-conf
          configMap:
            name: nginx-conf
EOF
    ;;
"off")
    kubectl delete -n app-${APPNAME} deploy snipe-it nginx
    ;;
*)
    echo $(basename $0) on/off
    ;;
esac
