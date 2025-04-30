#!/usr/bin/env bash

set -e

echo "Adding $DEPLOY_ADMIN_OID as deployment admin"
short_id="$(echo "$DEPLOY_ADMIN_OID" | cut -c1-7)"
kubectl create clusterrolebinding "$short_id-deploy-binding" \
  --clusterrole cluster-admin \
  --user="$DEPLOY_ADMIN_OID" \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Finished!"
