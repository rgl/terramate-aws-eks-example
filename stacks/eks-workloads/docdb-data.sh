#!/bin/bash
set -euo pipefail

eval "$(jq -r '@sh "DOCDB_NAME=\(.name)"')"

DOCDB_ENDPOINT="$(aws docdb describe-db-clusters \
    --db-cluster-identifier "$DOCDB_NAME" \
    --query 'DBClusters[*].Endpoint' \
    | jq -r '.[0]')"

jq -n \
    --arg endpoint "$DOCDB_ENDPOINT" \
    '{"endpoint":$endpoint}'
