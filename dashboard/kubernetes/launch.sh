#!/bin/bash

[ ! -f kubernetes-dashboard.yaml ] && \
	wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f kubernetes-dashboard.yaml
echo url: http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard:/proxy/
kubectl proxy
kubectl delete -f kubernetes-dashboard.yaml
