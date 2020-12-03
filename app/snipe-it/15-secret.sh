#!/bin/bash

SECRET_STORE=${SECRET_STORE:-${STORE}/app-secret}
APPNAME=${APPNAME:-snipe-it}

ACTION=$1
case $ACTION in
"on")
    gpg -d ${SECRET_STORE}/${APPNAME}-secret.enc | kubectl apply -f -
    ;;
"off")
    kubectl delete -n app-${APPNAME} secret ${APPNAME}-secret
    ;;
"preflight")
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${APPNAME}-secret
  namespace: app-${APPNAME}
type: Opaque
data:
  APP_KEY: $(echo base64:$(gpg --gen-random --armor 2 32) | head -c-1 | base64 -w0 | sed 's/\//_/g')
EOF
    kubectl get secret ${APPNAME}-secret -o yaml -n app-${APPNAME} | gpg -ear $GPGKEY -o ${SECRET_STORE}/${APPNAME}-secret.enc
    ;;
*)
    echo $(basename $0) on/off/preflight
    ;;
esac
