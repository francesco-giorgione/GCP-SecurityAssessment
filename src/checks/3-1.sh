#!/bin/bash

# Usage check
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Set the active project with timeout
timeout 20 gcloud config set project "$PROJECT_ID" --quiet || {
  echo "ERROR: gcloud command timed out or failed while setting project."
  exit 3
}

# Get list of networks with timeout
echo "Fetching list of VPC networks for project: $PROJECT_ID"
NETWORKS=$(timeout 20 gcloud compute networks list --format="value(name)") || {
  echo "ERROR: gcloud command timed out or failed while fetching networks."
  exit 3
}

# Check if 'default' network exists
if echo "$NETWORKS" | grep -q "^default$"; then
  echo "NON-COMPLIANT: 'default' network exists in project '$PROJECT_ID'."
  exit 2
else
  echo "No default network found in project '$PROJECT_ID'."
  exit 0
fi
