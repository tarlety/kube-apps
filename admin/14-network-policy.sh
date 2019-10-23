#!/bin/bash

APPNAME=$1

kubectl label namespace app-${APPNAME} namespace=app-${APPNAME}

cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: app-${APPNAME}
  name: deny-from-other-namespaces
spec:
  podSelector:
    matchLables:
      namespace: app-${APPNAME}
  ingress:
  - from:
    - podSelector: {}
EOF

