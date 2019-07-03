#!/bin/bash

APPNAME=${APPNAME:-nextcloud}
NEXTCLOUD_REPLICAS=${NEXTCLOUD_REPLICAS:-1}

NEXTCLOUD_VERSION=${NEXTCLOUD_VERSION:-nextcloud:16.0.1-fpm}
NGINX_VERSION=${NGINX_VERSION:-nginx:1.17.0}

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
    app: nextcloud
spec:
  replicas: ${NEXTCLOUD_REPLICAS}
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
          lifecycle:
            postStart:
              exec:
                command:
                  - "/bin/sh"
                  - "-c"
                  - |
                    sed -in -e 's/^pm.max_children = .*/pm.max_children = 40/g' /usr/local/etc/php-fpm.d/www.conf
                    sed -in -e 's/^pm.start_servers = .*/pm.start_servers = 10/g' /usr/local/etc/php-fpm.d/www.conf
                    sed -in -e 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/g' /usr/local/etc/php-fpm.d/www.conf
                    sed -in -e 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 20/g' /usr/local/etc/php-fpm.d/www.conf
                    kill -USR2 1
                    echo '
                    mbstring.func_overload=0
                    always_populate_raw_post_data=-1
                    default_charset='UTF-8'
                    output_buffering=0
                    opcache.memory_consumption=256
                    opcache.interned_strings_buffer=8
                    opcache.max_accelerated_files=10000
                    opcache.validate_timestamps=0
                    opcache.save_comments=1
                    opcache.huge_code_pages=1
                    opcache.file_cache=/tmp
                    ' > /var/www/html/.user.ini
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: normal
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: app-${APPNAME}
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
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
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cron
  namespace: app-${APPNAME}
  labels:
    app: cron
spec:
  schedule: "*/15 * * * *"
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
            image: ${NEXTCLOUD_VERSION}
            imagePullPolicy: IfNotPresent
            command: ["curl"]
            args:
            - "--fail"
            - http://web/cron.php
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy nextcloud nginx
	kubectl delete -n app-${APPNAME} cronjob cron
	;;
*)
	echo "$(basename $0) on/off"
	echo ""
	echo "Nextcloud Replicas can be scaled up runtime."
	echo "Ex:"
	echo "NEXTCLOUD_REPLICAS=3 ./$(basename $0) on"
	;;
esac