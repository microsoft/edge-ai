#!/usr/bin/env bash
JWT=$1
URL=$2

response=$(curl --request POST \
--url "$URL" \
--header "Accept: application/vnd.github+json" \
--header "Authorization: Bearer $JWT" \
--header "X-GitHub-Api-Version: 2022-11-28")

echo "$response" | jq -r '.token'