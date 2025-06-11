#!/bin/bash

# Usage check
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Set the active project
gcloud config set project "$PROJECT_ID" --quiet

# Get list of networks
echo "Fetching list of VPC networks for project: $PROJECT_ID"
NETWORKS=$(gcloud compute networks list --format="value(name)")

# Check if 'default' network exists
if echo "$NETWORKS" | grep -q "^default$"; then
  echo "NON-COMPLIANT: 'default' network exists in project '$PROJECT_ID'."
  exit 1
else
  echo "No default network found in project '$PROJECT_ID'."
fi
