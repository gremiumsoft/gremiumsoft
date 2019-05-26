#!/usr/bin/env bash

set -ex

minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.14.2 -p gremium
minikube profile gremium

kubectl cluster-info

mkdir -p tmp
cd tmp
if [[ ! -d istio ]]; then
  git clone git@github.com:istio/istio.git
  cd istio
  git checkout 1.1.2
else
  cd istio
fi

kubectl create namespace istio-system

helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
sleep 120  # completely random number
# TODO(JN): disable prometheus
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
sleep 120

cd ../..

kubectl label namespace default istio-injection=enabled

kubectl apply -f ./kube-config/gateway.yaml

COMPONENTS=(
  'frontend-ui'
  'go/src/frontend'
  'go/src/quizservice'
)

source source.sh

for component in ${COMPONENTS[@]};
do
(
  cd ${component}
  make docker-build
  make kube-apply
)
done

#export GATEWAY_URL=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
#echo $GATEWAY_URL
echo "Run 'minikube tunnel' and use istio-ingressgateway External IP"
kubectl -n istio-system get services