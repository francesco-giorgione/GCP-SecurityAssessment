#!/bin/bash

# Check input
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Set project
gcloud config set project "$PROJECT_ID" --quiet

# List instances with their IP forwarding setting
echo "Checking instances for IP forwarding..."
OUTPUT=$(gcloud compute instances list --format='table(name,canIpForward)' --project="$PROJECT_ID")

# Filter only instances with canIpForward = true
FORWARDING_INSTANCES=$(echo "$OUTPUT" | grep -i -w "true")

if [ -n "$FORWARDING_INSTANCES" ]; then
  echo ""
  echo "⚠️  Warning: The following instances have IP forwarding enabled:"
  echo "$FORWARDING_INSTANCES"
  exit 1
else
  echo ""
  echo "✅ All instances have IP forwarding disabled."
fi
