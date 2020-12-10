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
  MAIL_HOST: $(echo 'changeme.localhost.localdomain' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_PORT: $(echo '0' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_USERNAME: $(echo 'chageme' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_PASSWORD: $(echo 'chageme' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_ENCRYPTION: $(echo 'false' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_FROM_ADDR: $(echo 'changeme@localhost.localdomain' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_FROM_NAME: $(echo 'changeme' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_REPLYTO_ADDR: $(echo 'chaneme@localhost.localdomain' | head -c-1 | base64 -w0 | sed 's/\//_/g')
  MAIL_REPLYTO_NAME: $(echo 'chageme' | head -c-1 | base64 -w0 | sed 's/\//_/g')
EOF
    kubectl get secret ${APPNAME}-mail -o yaml -n app-${APPNAME} | gpg -ear $GPGKEY -o ${SECRET_STORE}/${APPNAME}-mail.enc
    ;;
*)
    echo $(basename $0) on/off/preflight
    ;;
esac
