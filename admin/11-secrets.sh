#!/bin/bash

APPNAME=$1

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: passwords
  namespace: app-${APPNAME}
type: Opaque
data:
  admin-password: $(gpg --gen-random --armor 2 20 | head -c-1 | base64 -w0 | sed 's/\//_/g')
  user-password: $(gpg --gen-random --armor 2 20 | head -c-1 | base64 -w0 | sed 's/\//_/g')
  mon-password: $(gpg --gen-random --armor 2 20 | head -c-1 | base64 -w0 | sed 's/\//_/g')
  rest-password: $(gpg --gen-random --armor 2 20 | head -c-1 | base64 -w0 | sed 's/\//_/g')
EOF
