#!/bin/bash

# Load environment variables from .env file in the same directory as the script
if [ ! -f .env ]; then
  echo "Error: .env file not found!"
  exit 1
fi

set -o allexport
source .env
set +o allexport

# Check that PROJECT_ID is set from .env
if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID not set in .env file."
  exit 1
fi

# Check that USER_EMAIL is passed as first argument
if [ -z "$1" ]; then
  echo "Usage: $0 <USER_EMAIL>"
  exit 1
fi

USER_EMAIL="$1"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="allUsers" \
  --role="roles/viewer"

echo "Adding IAM policy binding..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --quiet

if [[ $? -eq 0 ]]; then
  echo "Successfully assigned roles/iam.serviceAccountTokenCreator to $USER_EMAIL in project $PROJECT_ID"
else
  echo "Failed to assign role. Please check your permissions and inputs."
  exit 1
fi
