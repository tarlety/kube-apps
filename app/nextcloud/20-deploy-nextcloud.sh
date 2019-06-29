#!/bin/bash

APPNAME=${APPNAME:-nextcloud}

NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION:-nextcloud:16.0.1-fpm}
NGINX_VERSION=${NGINX_VERSION:-nginx:1.17.0}

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
  replicas: 1
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
            - name: nextcloud
              containerPort: 9000
              protocol: TCP
          volumeMounts:
            - mountPath: /var/www/html
              name: data
              subPath: html
        - image: ${NGINX_VERSION}
          name: nginx
          imagePullPolicy: IfNotPresent
          ports:
            - name: web
              containerPort: 80
              protocol: TCP
          volumeMounts:
            - mountPath: /var/www/html
              name: data
              subPath: html
            - mountPath: /etc/nginx/conf.d
              name: nginx-conf
              readOnly: true
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
      - name: nginx-conf
        configMap:
          name: nginx-conf
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy nextcloud
	;;
*)
	echo $(basename $0) on/off
	;;
esac
