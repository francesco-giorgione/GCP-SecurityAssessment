#!/bin/bash

# Check input
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Set project with timeout
timeout 20 gcloud config set project "$PROJECT_ID" --quiet || {
  echo "ERROR: gcloud command timed out or failed while setting project."
  exit 3
}

# List instances with their IP forwarding setting with timeout
echo "Checking instances for IP forwarding..."
OUTPUT=$(timeout 20 gcloud compute instances list --format='table(name,canIpForward)' --project="$PROJECT_ID") || {
  echo "ERROR: gcloud command timed out or failed while listing instances."
  exit 3
}

# Filter only instances with canIpForward = true
FORWARDING_INSTANCES=$(echo "$OUTPUT" | grep -i -w "true")

if [ -n "$FORWARDING_INSTANCES" ]; then
  echo ""
  echo "NON-COMPLIANT: The following instances have IP forwarding enabled:"
  echo "$FORWARDING_INSTANCES"
  exit 2
else
  echo ""
  echo "All instances have IP forwarding disabled."
  exit 0
fi
