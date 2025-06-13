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

# Try to retrieve IAM policy with timeout
case "$MODE" in
  --org)
    echo "Scanning IAM policy for organization ID: $ID"
    IAM_JSON=$(timeout 20 gcloud organizations get-iam-policy "$ID" --format=json) || {
      echo "ERROR: gcloud command timed out or failed while retrieving org IAM policy."
      exit 3
    }
    ;;
  --project)
    echo "Scanning IAM policy for project ID: $ID"
    IAM_JSON=$(timeout 20 gcloud projects get-iam-policy "$ID" --format=json) || {
      echo "ERROR: gcloud command timed out or failed while retrieving project IAM policy."
      exit 3
    }
    ;;
  --folder)
    echo "Scanning IAM policy for folder ID: $ID"
    IAM_JSON=$(timeout 20 gcloud resource-manager folders get-iam-policy "$ID" --format=json) || {
      echo "ERROR: gcloud command timed out or failed while retrieving folder IAM policy."
      exit 3
    }
    ;;
  *)
    echo "ERROR: Invalid mode. Use --org, --project, or --folder."
    exit 1
    ;;
esac

echo "Allowed domain: $AUTHORIZED_DOMAIN"
echo "----------------------------------------------------"

NON_COMPLIANT_FOUND=0  # Flag to track non-compliance

# Extract and analyze IAM members
MEMBERS=$(echo "$IAM_JSON" | jq -r '.bindings[].members[]' | sort | uniq)
while read -r MEMBER; do
  TYPE=$(echo "$MEMBER" | cut -d':' -f1)
  IDENTIFIER=$(echo "$MEMBER" | cut -d':' -f2-)

  case "$TYPE" in
    user)
      if [[ ! "$IDENTIFIER" =~ @([a-zA-Z0-9.-]+\.)?$AUTHORIZED_DOMAIN$ ]]; then
        echo "NON-COMPLIANT: External user detected: $IDENTIFIER"
        NON_COMPLIANT_FOUND=1
      fi
      ;;
    serviceAccount)
      if [[ "$IDENTIFIER" != *"@$AUTHORIZED_DOMAIN" && "$IDENTIFIER" != *".gserviceaccount.com" ]]; then
        echo "NON-COMPLIANT: External service account detected: $IDENTIFIER"
        NON_COMPLIANT_FOUND=1
      fi
      ;;
    *)
      :
      ;;
  esac
done <<< "$MEMBERS"

# Exit with code 2 if any non-compliant member found
if [[ $NON_COMPLIANT_FOUND -eq 1 ]]; then
  exit 2
fi

exit 0
