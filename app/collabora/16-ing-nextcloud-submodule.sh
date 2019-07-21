#!/bin/bash

# issue: I have an ingress rule on a subpath (/collabora) pointing to collabora. collabora is a webapp that run on the / path.
# https://www.reddit.com/r/kubernetes/comments/b2v74a/traefik_as_ingress_controller_strip_path_prefix/

APPNAME=${APPNAME:-collabora}
DOMAIN=${DOMAIN:-minikube}

ACTION=$1
case $ACTION in
"on")
	cat <<EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-nextcloud-collabora
  namespace: app-${APPNAME}
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.frontend.rule.type: PathPrefixStrip
spec:
  rules:
  - host: nextcloud.${DOMAIN}
    http:
      paths:
      - path: /collabora
        backend:
          serviceName: web
          servicePort: web
EOF
	;;
"off")
	kubectl delete -n app-${APPNAME} ing ingress-nextcloud-collabora
	;;
*)
	echo "$(basename $0) on/off"
	;;
esac

