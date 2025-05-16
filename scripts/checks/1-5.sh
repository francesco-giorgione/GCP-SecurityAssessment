#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# List of admin roles to check against
ADMIN_ROLES=(
  "roles/owner"
  "roles/editor"
  "roles/resourcemanager.organizationAdmin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/iam.admin"
  "roles/iam.securityAdmin"
  "roles/compute.admin"
  "roles/storage.admin"
  "roles/cloudsql.admin"
  "roles/appengine.appAdmin"
  "roles/kms.admin"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/bigquery.admin"
)

echo "Checking user-created service accounts with admin roles in project: $PROJECT_ID"
echo "--------------------------------------------------------------------------"

# List all user-managed service accounts
ALL_USER_MANAGED_SAS=$(gcloud iam service-accounts list --project="$PROJECT_ID" --format="value(email)")

# Filter only user-created accounts (not default Google-managed, even if user-managed)
USER_CREATED_SAS=$(echo "$ALL_USER_MANAGED_SAS" | grep "@$PROJECT_ID.iam.gserviceaccount.com" | grep -Ev '^(compute|appspot|firebase|cloud-functions|cloud-run|gcf|gae|composer|dataproc|gke|cloudbuild|artifactregistry|deploymentmanager)-')

echo "Identified user-created service accounts:"
echo "$USER_CREATED_SAS"
echo "--------------------------------------------------------------------------"

# Get IAM policy for the project
IAM_POLICY=$(gcloud projects get-iam-policy "$PROJECT_ID" --format="json")

NON_COMPLIANT=0

for SA_EMAIL in $USER_CREATED_SAS; do
  for ROLE in "${ADMIN_ROLES[@]}"; do
    MATCH=$(echo "$IAM_POLICY" | jq -r --arg ROLE "$ROLE" --arg MEMBER "serviceAccount:$SA_EMAIL" '
      .bindings[]? | select(.role == $ROLE) | .members[]? | select(. == $MEMBER)')

    if [[ -n "$MATCH" ]]; then
      echo "Non-compliant: $MATCH has admin role $ROLE"
      NON_COMPLIANT=1
    fi
  done
done

if [[ "$NON_COMPLIANT" -eq 0 ]]; then
  echo "All user-created service accounts are compliant. No admin roles found."
else
  echo "One or more user-created service accounts have admin roles. Manual review recommended."
  exit 2
fi