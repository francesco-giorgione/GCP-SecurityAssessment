#!/bin/bash

# Load project ID from .env file
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found"
  exit 1
fi

if [[ -z "$PROJECT_ID" ]]; then
  echo "PROJECT_ID not set in .env"
  exit 1
fi

# --------- First Service Account: app-reader (with key) ---------
SA1_NAME="app-reader"
SA1_DISPLAY_NAME="App Reader"
SA1_DESCRIPTION="Reads from Cloud Storage"
SA1_EMAIL="${SA1_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
SA1_KEY_FILE="${SA1_NAME}-key.json"

echo "Checking if service account $SA1_EMAIL exists..."
EXISTS1=$(gcloud iam service-accounts list --project="$PROJECT_ID" \
  --filter="email:$SA1_EMAIL" \
  --format="value(email)")

if [[ -z "$EXISTS1" ]]; then
  echo "Creating service account $SA1_EMAIL..."
  gcloud iam service-accounts create "$SA1_NAME" \
    --project="$PROJECT_ID" \
    --display-name="$SA1_DISPLAY_NAME" \
    --description="$SA1_DESCRIPTION"
else
  echo "Service account $SA1_EMAIL already exists. Skipping creation."
fi

echo "Assigning roles/storage.objectViewer to $SA1_EMAIL..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA1_EMAIL" \
  --role="roles/storage.objectViewer"

echo "Creating user-managed key for $SA1_EMAIL..."
gcloud iam service-accounts keys create "$SA1_KEY_FILE" \
  --iam-account="$SA1_EMAIL"


# --------- Second Service Account: app-logic (admin role, no key) ---------
SA2_NAME="app-logic"
SA2_DISPLAY_NAME="App Logic"
SA2_DESCRIPTION="Executes internal logic"
SA2_EMAIL="${SA2_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Checking if service account $SA2_EMAIL exists..."
EXISTS2=$(gcloud iam service-accounts list --project="$PROJECT_ID" \
  --filter="email:$SA2_EMAIL" \
  --format="value(email)")

if [[ -z "$EXISTS2" ]]; then
  echo "Creating service account $SA2_EMAIL..."
  gcloud iam service-accounts create "$SA2_NAME" \
    --project="$PROJECT_ID" \
    --display-name="$SA2_DISPLAY_NAME" \
    --description="$SA2_DESCRIPTION"
else
  echo "Service account $SA2_EMAIL already exists. Skipping creation."
fi

echo "Assigning roles/editor (admin) to $SA2_EMAIL..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA2_EMAIL" \
  --role="roles/editor"
