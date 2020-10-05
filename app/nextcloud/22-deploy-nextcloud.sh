#!/bin/bash

APPNAME=${APPNAME:-nextcloud}
REPLICAS=${REPLICAS:-1}

# https://hub.docker.com/_/nextcloud
NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION:-nextcloud:19.0.3-fpm}
# https://hub.docker.com/_/nginx
NGINX_VERSION=${NGINX_VERSION:-nginx:1.19.2}
# https://hub.docker.com/_/alpine
ALPINE_VERSION=${ALPINE_VERSION:-alpine:3.12.0}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextcloud
  namespace: app-${APPNAME}
  labels:
    type: app
    app: nextcloud
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: nextcloud
  template:
    metadata:
      labels:
        type: app
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
          volumeMounts:
            - mountPath: /var/www/html
              name: data
              subPath: html
            - mountPath: "/backup"
              name: backup
          lifecycle:
            postStart:
              exec:
                command:
                  - "/bin/sh"
                  - "-c"
                  - |
                    sed -in -e 's/^pm.max_children = .*/pm.max_children = 300/g' /usr/local/etc/php-fpm.d/www.conf
                    sed -in -e 's/^pm.start_servers = .*/pm.start_servers = 30/g' /usr/local/etc/php-fpm.d/www.conf
                    sed -in -e 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 20/g' /usr/local/etc/php-fpm.d/www.conf
                    sed -in -e 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 50/g' /usr/local/etc/php-fpm.d/www.conf
                    apt-get update -y
                    apt-get install libsmbclient-dev -y
                    pecl install smbclient
                    echo 'extension=smbclient.so' | tee -a /usr/local/etc/php/conf.d/docker-php-ext-intl.ini
                    kill -USR2 1
          resources:
            requests:
              cpu: 1000m
              memory: "8Gi"
            limits:
              cpu: 2000m
              memory: "16Gi"
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
      - name: backup
        persistentVolumeClaim:
          claimName: cold
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cron
  namespace: app-${APPNAME}
  labels:
    type: app
    app: cron
spec:
  schedule: "*/15 * * * *"
  successfulJobsHistoryLimit: 4
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid
  jobTemplate:
    metadata:
      labels:
        app: cron
    spec:
      template:
        metadata:
          labels:
            app: cron
        spec:
          restartPolicy: Never
          containers:
          - name: cron
            image: ${ALPINE_VERSION}
            imagePullPolicy: IfNotPresent
            command:
            - "/usr/bin/wget"
            - "-O"
            - "-"
            - "https://nextcloud.${DOMAIN}/cron.php"
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy nextcloud
	kubectl delete -n app-${APPNAME} cronjob cron
	;;
*)
	echo "$(basename $0) on/off"
	echo ""
	echo "Replicas can be scaled up at runtime."
	echo "Ex:"
	echo "REPLICAS=3 ./$(basename $0) on"
	;;
esac
