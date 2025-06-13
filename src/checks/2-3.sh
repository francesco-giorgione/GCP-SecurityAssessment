#!/bin/bash

# Check if project ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"
NON_COMPLIANT_FOUND=0  # Flag to track non-compliance

echo "Listing sinks in project '$PROJECT_ID' that export to Cloud Storage..."

# Get all sinks for the project that export to storage (with timeout)
SINKS=$(timeout 20 gcloud logging sinks list --project="$PROJECT_ID" --format="json") || {
  echo "ERROR: gcloud command timed out after 20 seconds while listing sinks."
  exit 3
}

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

  # Get retention info once (with timeout)
  RETENTION_OUTPUT=$(timeout 20 gsutil retention get gs://$BUCKET_NAME 2>/dev/null) || {
    echo "ERROR: gsutil command timed out after 20 seconds or access denied for bucket: $BUCKET_NAME"
    NON_COMPLIANT_FOUND=1
    continue
  }

  if [ -z "$RETENTION_OUTPUT" ]; then
    echo "Could not retrieve retention policy or bucket does not exist or access is denied."
  else
    echo "Retention policy:"
    echo "$RETENTION_OUTPUT"

    if echo "$RETENTION_OUTPUT" | grep -q "Duration"; then
      echo "Retention policy is set."
    else
      echo "NON-COMPLIANT: no retention policy is set. Manual review recommended!"
      NON_COMPLIANT_FOUND=1
    fi
  fi
done

# Exit with code 2 if any non-compliant bucket found
if [ $NON_COMPLIANT_FOUND -eq 1 ]; then
  exit 2
fi

exit 0
