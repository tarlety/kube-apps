#!/bin/bash

APPNAME=${APPNAME:-hackmd}
REPLICAS=${REPLICAS:-1}

HACKMD_VERSION=${HACKMD_VERSION:-hackmdio/hackmd:2.1.0}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hackmd
  namespace: app-${APPNAME}
  labels:
    type: app
    app: hackmd
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: hackmd
  template:
    metadata:
      labels:
        type: app
        app: hackmd
    spec:
      containers:
        - image: ${HACKMD_VERSION}
          name: hackmd
          imagePullPolicy: IfNotPresent
          envFrom:
            - secretRef:
                name: ${APPNAME}-ldap
          env:
            - name: CMD_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: passwords
                  key: user-password
            - name: CMD_DB_URL
              value: postgres://hackmd:\$(CMD_DB_PASSWORD)@postgres:5432/hackmd
            - name: CMD_ALLOW_EMAIL_REGISTER
              value: "false"
            - name: CMD_ALLOW_ANONYMOUS
              value: "false"
            - name: CMD_DEFAULT_PERMISSION
              value: "private"
            - name: CMD_IMAGE_UPLOAD_TYPE
              value: "filesystem"
            - name: CMD_DOMAIN
              value: hackmd.${DOMAIN}
            - name: CMD_PROTOCOL_USESSL
              value: "true"
            - name: CMD_URL_ADDPORT
              value: "3000"
            - name: CMD_USECDN
              value: "false"
          ports:
            - name: web
              containerPort: 3000
              protocol: TCP
          volumeMounts:
            - mountPath: "/home/hackmd/app/public/uploads"
              name: data
              subPath: uploads
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: normal
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy hackmd
	;;
*)
	echo "$(basename $0) on/off"
	echo ""
	echo "Replicas can be scaled up at runtime."
	echo "Ex:"
	echo "REPLICAS=3 ./$(basename $0) on"
	;;
esac
