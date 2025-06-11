#!/bin/bash

# Usage:
#   ./check_iam_externals.sh --org ORGANIZATION_ID AUTHORIZED_DOMAIN
#   ./check_iam_externals.sh --project PROJECT_ID AUTHORIZED_DOMAIN
#   ./check_iam_externals.sh --folder FOLDER_ID AUTHORIZED_DOMAIN

MODE="$1"
ID="$2"
AUTHORIZED_DOMAIN="$3"

if [[ -z "$MODE" || -z "$ID" || -z "$AUTHORIZED_DOMAIN" ]]; then
  echo "ERROR: Usage:"
  echo "  $0 --org ORGANIZATION_ID AUTHORIZED_DOMAIN"
  echo "  $0 --project PROJECT_ID AUTHORIZED_DOMAIN"
  echo "  $0 --folder FOLDER_ID AUTHORIZED_DOMAIN"
  exit 1
fi

case "$MODE" in
  --org)
    echo "Scanning IAM policy for organization ID: $ID"
    IAM_JSON=$(gcloud organizations get-iam-policy "$ID" --format=json)
    ;;
  --project)
    echo "Scanning IAM policy for project ID: $ID"
    IAM_JSON=$(gcloud projects get-iam-policy "$ID" --format=json)
    ;;
  --folder)
    echo "Scanning IAM policy for folder ID: $ID"
    IAM_JSON=$(gcloud resource-manager folders get-iam-policy "$ID" --format=json)
    ;;
  *)
    echo "ERROR: Invalid mode. Use --org, --project, or --folder."
    exit 1
    ;;
esac

echo "Allowed domain: $AUTHORIZED_DOMAIN"
echo "----------------------------------------------------"

# Extract and analyze IAM members
echo "$IAM_JSON" | jq -r '.bindings[].members[]' | sort | uniq | while read -r MEMBER; do
  TYPE=$(echo "$MEMBER" | cut -d':' -f1)
  IDENTIFIER=$(echo "$MEMBER" | cut -d':' -f2-)

  case "$TYPE" in
    user)
      if [[ "$IDENTIFIER" != *"@$AUTHORIZED_DOMAIN" ]]; then
        echo "External user detected: $IDENTIFIER"
      fi
      ;;
    serviceAccount)
      if [[ "$IDENTIFIER" != *"@$AUTHORIZED_DOMAIN" && "$IDENTIFIER" != *".gserviceaccount.com" ]]; then
        echo "External service account detected: $IDENTIFIER"
      fi
      ;;
    *)
      # Other types (e.g., group, domain, etc.) can be handled if needed
      :
      ;;
  esac
done

echo "✅ Scan completed."
