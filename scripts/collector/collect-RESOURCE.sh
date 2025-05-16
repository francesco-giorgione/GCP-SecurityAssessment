#!/bin/bash

PROJECT_ID="pteh-02"
ACCESS_TOKEN=$(gcloud auth print-access-token)
TMP_FILE="page.json"
NEXT_TOKEN=""
PAGE_COUNT=1

> merged_assets.jsonl  # JSONL format (one JSON object per line)

while true; do
  echo "Requesting page $PAGE_COUNT..."

  if [ -z "$NEXT_TOKEN" ]; then
    BODY='{"contentType": "RESOURCE"}'
  else
    BODY=$(jq -n --arg token "$NEXT_TOKEN" '{"contentType": "RESOURCE", "pageToken": $token}')
  fi

  curl -s -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "X-HTTP-Method-Override: GET" \
    -d "$BODY" \
    "https://cloudasset.googleapis.com/v1/projects/$PROJECT_ID/assets" > "$TMP_FILE"

  # Check for error
  if jq -e '.error' "$TMP_FILE" > /dev/null; then
    echo "API error:"
    cat "$TMP_FILE"
    rm "$TMP_FILE"
    exit 1
  fi

  # Append each asset as JSON line
  jq -c '.assets[]?' "$TMP_FILE" >> merged_assets.jsonl

  NEXT_TOKEN=$(jq -r '.nextPageToken // empty' "$TMP_FILE")
  if [ -z "$NEXT_TOKEN" ]; then
    break
  fi
  PAGE_COUNT=$((PAGE_COUNT + 1))
done

# Convert JSONL to valid array
echo "[" > resources.json
awk 'NR>1{print ","} {print}' merged_assets.jsonl >> resources.json
echo "]" >> resources.json

rm "$TMP_FILE" merged_assets.jsonl

echo "All assets saved to resources.json"