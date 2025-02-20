#!/usr/bin/env bash
TOKEN=$1
BRANCH=$2
COMMITMSG=$3

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/commercial-software-engineering/Iac-for-the-Edge/pulls \
  -d "{\"title\":\"AzDO merge for branch $BRANCH\",\"body\":\"Sync from AzDO - IaC for the Edge repo having the following changes: $COMMITMSG\",\"head\":\"$BRANCH\",\"base\":\"main\"}"