#!/bin/bash

# Check for project ID argument
if [[ -z "$1" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

echo "Scanning user-managed service accounts in project: $PROJECT_ID"
echo "--------------------------------------------------------------"

# Get list of user-managed service accounts with a 20s timeout
SA_LIST=$(timeout 20 gcloud iam service-accounts list --project="$PROJECT_ID" \
  --format="value(email)" | grep "@$PROJECT_ID.iam.gserviceaccount.com") || {
    echo "ERROR: gcloud command timed out or failed while listing service accounts."
    exit 3
}

if [[ -z "$SA_LIST" ]]; then
  echo "No user-managed service accounts found."
  exit 0
fi

NON_COMPLIANT_FOUND=0

for SA in $SA_LIST; do
  echo "Checking keys for: $SA"

  KEYS=$(timeout 20 gcloud iam service-accounts keys list \
    --iam-account="$SA" \
    --managed-by=user \
    --format="value(name)") || {
      echo "ERROR: gcloud command timed out or failed while listing keys for $SA"
      exit 3
  }

  if [[ -n "$KEYS" ]]; then
    echo "NON-COMPLIANT: user-managed keys found for $SA"
    NON_COMPLIANT_FOUND=1
  else
    echo "Compliant: no user-managed keys found for $SA"
  fi
done

echo "--------------------------------------------------------------"

if [[ "$NON_COMPLIANT_FOUND" -eq 1 ]]; then
  echo "Some service accounts have user-managed keys. Review required."
  exit 2
else
  echo "All user-managed service accounts are compliant."
  exit 0
fi
