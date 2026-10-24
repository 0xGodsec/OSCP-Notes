#!/usr/bin/env bash
# Load the OSCP custom Cypher queries into a BloodHound CE instance.
# CE stores saved queries in its DB (not a customqueries.json file), so this
# POSTs each query to the CE API. They then appear under Cypher -> Saved Queries
# as clickable buttons and persist across restarts.
#
# USAGE:
#   1. Log into the CE web UI (default http://localhost:8080).
#   2. Grab a bearer token: open DevTools -> Network -> click any request to
#      /api/v2/... -> copy the "Authorization: Bearer <JWT>" value (the JWT part).
#   3. Run:  BHCE_URL=http://localhost:8080 BHCE_JWT='<JWT>' \
#              ./load-bloodhound-ce-queries.sh bloodhound-ce-custom-queries.json
#
# Needs: bash, curl, jq. Local instance only; no creds are stored by this script.
set -euo pipefail

JSON="${1:-bloodhound-ce-custom-queries.json}"
URL="${BHCE_URL:-http://localhost:8080}"
JWT="${BHCE_JWT:-}"

if [[ -z "$JWT" ]]; then
  echo "ERROR: set BHCE_JWT to your CE bearer token (see header of this script)." >&2
  exit 1
fi
if [[ ! -f "$JSON" ]]; then
  echo "ERROR: queries file not found: $JSON" >&2
  exit 1
fi

count=$(jq '.queries | length' "$JSON")
echo "Loading $count queries into $URL ..."

jq -c '.queries[]' "$JSON" | while read -r row; do
  name=$(jq -r '.name' <<<"$row")
  query=$(jq -r '.query' <<<"$row")
  body=$(jq -n --arg n "$name" --arg q "$query" '{name:$n, query:$q}')
  http=$(curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "$URL/api/v2/saved-queries" \
    -H "Authorization: Bearer $JWT" \
    -H 'Content-Type: application/json' \
    --data "$body" || echo 000)
  case "$http" in
    200|201) echo "  [ok]   $name" ;;
    409)     echo "  [skip] $name (already exists)" ;;
    *)       echo "  [FAIL $http] $name" ;;
  esac
done
echo "Done. Open CE -> Cypher -> Saved Queries."
