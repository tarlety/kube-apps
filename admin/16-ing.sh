#!/bin/bash

APPNAME=$1
DOMAIN=$2

cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress
  namespace: app-${APPNAME}
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: ${APPNAME}.${DOMAIN}
    http:
      paths:
      - path: /
        backend:
          serviceName: web
          servicePort: web
EOF
