#!/bin/bash

# Usage: ./create_user_token_creator.sh <PROJECT_ID> <USER_EMAIL>

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <PROJECT_ID> <USER_EMAIL>"
  exit 1
fi

PROJECT_ID="$1"
USER_EMAIL="$2"

gcloud projects add-iam-policy-binding [PROJECT_ID] \
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
