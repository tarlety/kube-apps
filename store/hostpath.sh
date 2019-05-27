#!/bin/bash

ACTION=$1
NAMESPACE=$2
PVCNAME=$3
CAPACITY=$4
HOSTPATH=$5

case ${ACTION} in
	"create")
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
		;;
	"delete")
		kubectl delete pv ${NAMESPACE}-${PVCNAME}
		;;
	"secret")
		;;
esac
