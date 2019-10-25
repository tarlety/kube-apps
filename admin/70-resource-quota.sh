#!/bin/bash

APPNAME=$1

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  namespace: app-${APPNAME}
  name: cpu-mem
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 16Gi
EOF

