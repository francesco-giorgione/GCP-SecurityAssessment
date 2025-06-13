#!/bin/bash

# Ensure project ID is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Set active project with timeout
timeout 20 gcloud config set project "$PROJECT_ID" --quiet || {
  echo "ERROR: gcloud command timed out or failed while setting project."
  exit 3
}

echo "Checking for non-GKE instances with public IPs in project '$PROJECT_ID'..."

# Get instance list as JSON with timeout
JSON_OUTPUT=$(timeout 20 gcloud compute instances list --project="$PROJECT_ID" --format=json) || {
  echo "ERROR: gcloud command timed out or failed while listing instances."
  exit 3
}

# Find VMs that:
# 1. Have accessConfigs (i.e., public IP)
# 2. AND are NOT GKE nodes (name doesn't start with 'gke-' AND no label 'goog-gke-node')

VM_WITH_PUBLIC_IPS=$(echo "$JSON_OUTPUT" | jq -r '
  .[]
  | select(
      (.networkInterfaces[].accessConfigs != null)
      and
      (
        (.name | startswith("gke-") | not)
        or
        (.labels["goog-gke-node"] == null)
      )
    )
  | .name
')

# Output results
if [ -n "$VM_WITH_PUBLIC_IPS" ]; then
  echo "NON-COMPLIANT: The following non-GKE instances are set to have public IP addresses:"
  echo "$VM_WITH_PUBLIC_IPS"
  exit 2
else
  echo "No public IPs found on non-GKE instances in project '$PROJECT_ID'."
  exit 0
fi
