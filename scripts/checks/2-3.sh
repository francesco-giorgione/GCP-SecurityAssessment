#!/bin/bash

# Check if project ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

echo "Listing sinks in project '$PROJECT_ID' that export to Cloud Storage..."

# Get all sinks for the project that export to storage
SINKS=$(gcloud logging sinks list --project="$PROJECT_ID" --format="json")

# Extract only storage bucket destinations
BUCKET_URLS=$(echo "$SINKS" | jq -r '.[] | select(.destination | startswith("storage.googleapis.com/")) | .destination')

if [ -z "$BUCKET_URLS" ]; then
  echo "No Cloud Storage sinks found in project '$PROJECT_ID'."
  exit 0
fi

echo "Found the following Cloud Storage sinks:"
echo "$BUCKET_URLS"

# Loop through each bucket and check retention and lock
for DEST in $BUCKET_URLS; do
  BUCKET_NAME=$(echo "$DEST" | sed 's#storage.googleapis.com/##')
  echo ""
  echo "Checking bucket: gs://$BUCKET_NAME"

  # Get retention info once
  RETENTION_OUTPUT=$(gsutil retention get gs://$BUCKET_NAME 2>/dev/null)

  if [ -z "$RETENTION_OUTPUT" ]; then
    echo "Could not retrieve retention policy or bucket does not exist or access is denied."
  else
    echo "Retention policy:"
    echo "$RETENTION_OUTPUT"

    HAS_RETENTION=$(echo "$RETENTION_OUTPUT" | grep "retentionPeriod")

    if echo "$RETENTION_OUTPUT" | grep -q "Duration"; then
      echo "Retention policy is set."
    else
      echo "NON-COMPLIANT: no retention policy is set. Manual review recommended!"
    fi
  fi
done
