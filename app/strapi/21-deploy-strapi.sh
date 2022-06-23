#!/bin/bash

APPNAME=${APPNAME:-strapi}
REPLICAS=${REPLICAS:-1}

# https://hub.docker.com/r/strapi/strapi
#STRAPI_VERSION=${STRAPI_VERSION:-strapi/strapi:3.6.8-node14-alpine}
STRAPI_VERSION=${STRAPI_VERSION:-tarlety/strapi:4.1.5}

ACTION=$1
case $ACTION in
"on")
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strapi
  namespace: app-${APPNAME}
  labels:
    type: app
    app: strapi
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: strapi
  template:
    metadata:
      labels:
        type: app
        app: strapi
    spec:
      containers:
        - image: ${STRAPI_VERSION}
          name: strapi
          imagePullPolicy: IfNotPresent
          envFrom:
            - configMapRef:
                name: strapi-env
          env:
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
          resources:
            requests:
              cpu: 2000m
              memory: "4Gi"
            limits:
              cpu: 4000m
              memory: "8Gi"
          ports:
            - name: web
              containerPort: 1337
              protocol: TCP
          volumeMounts:
            - mountPath: /srv/app
              name: data
              subPath: strapi
            - mountPath: /var/lib/backup
              name: backup
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
    kubectl delete -n app-${APPNAME} deploy strapi
    ;;
*)
    echo "$(basename $0) on/off"
    echo ""
    echo "Replicas can be scaled up at runtime."
    echo "Ex:"
    echo "REPLICAS=3 ./$(basename $0) on"
    ;;
esac
