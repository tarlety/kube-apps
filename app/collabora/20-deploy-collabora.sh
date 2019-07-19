#!/bin/bash

# https://www.collaboraoffice.com/code/quick-tryout-nextcloud-docker/
# https://www.collaboraoffice.com/code/docker/
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
  replicas: 3
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
            - name: extra_params
              value: "--o:ssl.enable=false"
          ports:
            - name: collabora
              containerPort: 80
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
