#!/bin/bash

SECRET_STORE=${SECRET_STORE:-${STORE}/app-secret}
APPNAME=${APPNAME:-snipe-it}

ACTION=$1
case $ACTION in
"on")
    gpg -d ${SECRET_STORE}/${APPNAME}-mail.enc | kubectl apply -f -
    ;;
"off")
    kubectl delete -n app-${APPNAME} secret ${APPNAME}-mail
    ;;
"preflight")
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${APPNAME}-mail
  namespace: app-${APPNAME}
type: Opaque
data:
  MAIL_HOST: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_PORT: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_USERNAME: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_PASSWORD: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_ENCRYPTION: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_FROM_ADDR: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_FROM_NAME: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_REPLYTO_ADDR: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_REPLYTO_NAME: $(echo '' | head -c-1 | base64 -w0 | sed 's/\//_/g')
EOF
    kubectl get secret ${APPNAME}-mail -o yaml -n app-${APPNAME} | gpg -ear $(whoami) -o ${SECRET_STORE}/${APPNAME}-mail.enc
    ;;
*)
    echo $(basename $0) on/off/preflight
    ;;
esac
