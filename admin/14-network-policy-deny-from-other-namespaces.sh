#!/bin/bash

APPNAME=$1

cat <<EOF | kubectl create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: app-${APPNAME}
  name: deny-from-other-namespaces
spec:
  podSelector:
    matchLables:
  ingress:
  - from:
    - podSelector: {}
EOF

