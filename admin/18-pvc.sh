#!/bin/bash

APPNAME=$1

cat <<EOF | kubectl create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: normal
  namespace: app-${APPNAME}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
EOF

cat <<EOF | kubectl create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: cold
  namespace: app-${APPNAME}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1000Gi
EOF

