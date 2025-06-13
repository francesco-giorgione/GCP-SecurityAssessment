#!/bin/bash

# Usage check
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"
BUCKET1="bucket-free-1-unique123456"
BUCKET2="bucket-free-2-unique123456"
SINK1_NAME="error-sink-bucket1"
SINK2_NAME="error-sink-bucket2"
LOG_FILTER='severity=ERROR'

# Create sink 1 - no retention
echo "Creating sink '$SINK1_NAME' for bucket: $BUCKET1"
gcloud logging sinks create "$SINK1_NAME" \
  "storage.googleapis.com/$BUCKET1" \
  --log-filter="$LOG_FILTER" \
  --project="$PROJECT_ID" \
  --quiet

# Create sink 2 - with retention
echo "Creating sink '$SINK2_NAME' for bucket: $BUCKET2"
gcloud logging sinks create "$SINK2_NAME" \
  "storage.googleapis.com/$BUCKET2" \
  --log-filter="$LOG_FILTER" \
  --project="$PROJECT_ID" \
  --quiet

# Set permanent retention (maximum possible: 36500 days ≈ 100 years)
echo "Setting permanent retention on bucket: $BUCKET2"
gsutil retention set 36500d gs://$BUCKET2

# (Optional) Lock the retention policy to make it permanent
echo "Locking retention policy on bucket: $BUCKET2 (cannot be undone)"
gsutil retention lock gs://$BUCKET2
