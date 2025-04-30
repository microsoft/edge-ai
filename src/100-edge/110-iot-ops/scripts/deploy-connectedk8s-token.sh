#!/usr/bin/env bash

set -e

kubectl create serviceaccount deploy-user -n default --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding deploy-user --clusterrole cluster-admin --serviceaccount default:deploy-user --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: deploy-user-secret
  annotations:
    kubernetes.io/service-account.name: deploy-user
type: kubernetes.io/service-account-token
EOF
TOKEN=$(kubectl get secret deploy-user-secret -o jsonpath='{$.data.token}' | base64 -d | sed 's/$/\n/g')

az keyvault secret set \
  --vault-name "$AKV_NAME" \
  --name "deploy-user-secret" \
  --content-type "text/plain" \
  --value "${TOKEN}" \
  --output none
