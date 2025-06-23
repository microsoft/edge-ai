#!/usr/bin/env bash
JWT=$1
REPO=$2

response=$(curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $JWT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$REPO/installation")

access_tokens_url=$(echo "$response" | jq -r '.access_tokens_url')
echo "$access_tokens_url"
