#!/bin/bash

# - how to use it
#  - https://www.collaboraoffice.com/code/quick-tryout-nextcloud-docker/
#  - https://www.collaboraoffice.com/code/docker/
# - admin page: https://collabora-online-domain/loleaflet/dist/admin/admin.html
# - troubleshooting restaring issue: https://github.com/CollaboraOnline/Docker-CODE/issues/32
APPNAME=${APPNAME:-collabora}
COLLABORA_VERSION=${COLLABORA_VERSION:-collabora/code:4.0.5.2}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: collabora
  namespace: app-${APPNAME}
  labels:
    type: app
    app: collabora
spec:
  selector:
    matchLabels:
      app: collabora
  template:
    metadata:
      labels:
        type: app
        app: collabora
    spec:
      containers:
        - image: ${COLLABORA_VERSION}
          name: collabora
          imagePullPolicy: IfNotPresent
          env:
            - name: DONT_GEN_SSL_CERT
              value: "true"
            - name: dictionaries
              value: "en_US"
            - name: domain
              value: "nextcloud.${DOMAIN}"
            - name: server_name
              value: "collabora.${DOMAIN}"
            - name: extra_params
              value: "--o:ssl.enable=false --o:ssl.termination=true"
            - name: SLEEPFORDEBUGGER
              value: "0"
          resources:
            requests:
              memory: "32Gi"
            limits:
              memory: "48Gi"
          ports:
            - name: web
              containerPort: 9980
              protocol: TCP
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} deploy collabora
	;;
*)
	echo "$(basename $0) on/off"
	;;
esac
