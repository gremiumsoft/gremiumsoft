#!/usr/bin/env bash

set -ex

minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.14.2

#kind create cluster --name gremium

#export KUBECONFIG="$(kind get kubeconfig-path --name="gremium")"
kubectl cluster-info

mkdir -p tmp
cd tmp
git clone git@github.com:istio/istio.git
cd istio
git checkout 1.1.2

kubectl create namespace istio-system
#helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system --set gateways.istio-ingressgateway.type=NodePort | kubectl apply -f -
helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
sleep 20  # completely random number
# TODO(JN): disable prometheus
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
sleep 120

cd ../..

kubectl label namespace default istio-injection=enabled

kubectl apply -f ./kube-config/gateway.yaml

kubectl apply -f ./frontend-ui/k8s/deployment.yaml
kubectl apply -f ./frontend-ui/k8s/service.yaml
kubectl apply -f ./frontend-ui/k8s/istio.yaml

sleep 10

export GATEWAY_URL=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
echo $GATEWAY_URL