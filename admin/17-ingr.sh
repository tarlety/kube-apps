#!/bin/bash

APPNAME=$1

cat <<EOF | kubectl create -f -
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute
  namespace: app-${APPNAME}

spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(\`${APPNAME}.${DOMAIN}\`)
      kind: Rule
      services:
        - name: web
          port: web
  tls: {}
EOF

