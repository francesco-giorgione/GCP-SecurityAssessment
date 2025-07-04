#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

echo "Checking user-created service accounts with high-privilege roles in project: $PROJECT_ID"
echo "----------------------------------------------------------------------------------------"

# List all user-managed service accounts with timeout
ALL_USER_MANAGED_SAS=$(timeout 20 gcloud iam service-accounts list --project="$PROJECT_ID" --format="value(email)") || {
  echo "ERROR: gcloud command timed out or failed while listing service accounts."
  exit 3
}

# Filter only user-created accounts (excluding system-managed patterns)
USER_CREATED_SAS=$(echo "$ALL_USER_MANAGED_SAS" | grep "@$PROJECT_ID.iam.gserviceaccount.com" | grep -Ev '^(compute|appspot|firebase|cloud-functions|cloud-run|gcf|gae|composer|dataproc|gke|cloudbuild|artifactregistry|deploymentmanager)-')

echo "Identified user-created service accounts:"
echo "$USER_CREATED_SAS"
echo "----------------------------------------------------------------------------------------"

# Get IAM policy for the project with timeout
IAM_POLICY=$(timeout 20 gcloud projects get-iam-policy "$PROJECT_ID" --format="json") || {
  echo "ERROR: gcloud command timed out or failed while retrieving IAM policy."
  exit 3
}

NON_COMPLIANT=0

for SA_EMAIL in $USER_CREATED_SAS; do
  MATCHES=$(echo "$IAM_POLICY" | jq -r --arg MEMBER "serviceAccount:$SA_EMAIL" '
    .bindings[]? | select(.members[]? == $MEMBER) | .role' | grep -Ei 'admin|roles/editor|roles/owner')

  if [[ -n "$MATCHES" ]]; then
    echo "NON-COMPLIANT: $SA_EMAIL has high-privilege roles:"
    echo "$MATCHES" | sed 's/^/  - /'
    NON_COMPLIANT=1
  fi
done

if [[ "$NON_COMPLIANT" -eq 0 ]]; then
  echo "All user-created service accounts are compliant. No high-privilege roles found."
  exit 0
else
  echo "One or more user-created service accounts have high-privilege roles. Manual review recommended."
  exit 2
fi
