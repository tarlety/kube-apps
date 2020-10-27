#!/bin/bash

SECRET_STORE=${SECRET_STORE:-${STORE}/app-secret}
APPNAME=${APPNAME:-hackmd}

ACTION=$1
case $ACTION in
"on")
	gpg -d ${SECRET_STORE}/hackmd-ldap.enc | kubectl apply -f -
	;;
"off")
	kubectl delete -n app-${APPNAME} secret ${APPNAME}-ldap
	;;
"preflight")
	cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${APPNAME}-ldap
  namespace: app-${APPNAME}
type: Opaque
data:
  CMD_EMAIL: $(echo "true" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_URL: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_BINDDN: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_BINDCREDENTIALS: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_SEARCHBASE: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_SEARCHFILTER: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_SEARCHATTRIBUTES: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_USERIDFIELD: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_USERNAMEFIELD: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
  CMD_LDAP_PROVIDERNAME: $(echo "" | head -c-1 | base64 -w0 | sed 's/\//_/g')
EOF
	kubectl get secret ${APPNAME}-ldap -o yaml -n app-${APPNAME} | gpg -ear $(whoami) -o ${SECRET_STORE}/${APPNAME}-ldap.enc
	;;
*)
	echo $(basename $0) on/off/preflight
	;;
esac
