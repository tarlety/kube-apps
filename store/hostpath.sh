#!/bin/bash

NAMESPACE=$1
PVCNAME=$2
CAPACITY=$3
HOSTPATH=$4

if [ "$NAMESPACE" == "" ] || [ "$PVCNAME" == "" ] || [ "$CAPACITY" == "" ] || [ "$HOSTPATH" == "" ] ; then
	echo Ex: $0 namespace pvc-name 5Gi /data/vol-path
	exit 1
fi

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${NAMESPACE}-${PVCNAME}
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: ${CAPACITY}
  claimRef:
    namespace: ${NAMESPACE}
    name: ${PVCNAME}
  hostPath:
    path: ${HOSTPATH}
EOF
