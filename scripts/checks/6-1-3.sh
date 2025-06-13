#!/bin/bash

# Check input
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"
NON_COMPLIANT_FOUND=0  # Flag per tenere traccia di non-compliance

# Set the active project (anche se non strettamente necessario per gcloud sql commands)
timeout 20 gcloud config set project "$PROJECT_ID" --quiet >/dev/null || {
  echo "ERROR: gcloud command timed out or failed while setting project."
  exit 3
}

# Retrieve list of MySQL instances with timeout
INSTANCES=$(timeout 20 gcloud sql instances list \
  --filter='DATABASE_VERSION:MYSQL*' \
  --format='value(NAME)') || {
    echo "ERROR: gcloud command timed out or failed while listing SQL instances."
    exit 3
}

if [ -z "$INSTANCES" ]; then
  echo "No MySQL instances found in project $PROJECT_ID"
  exit 0
fi

for INSTANCE in $INSTANCES; do
  echo "Checking instance: $INSTANCE"

  JSON_OUTPUT=$(timeout 20 gcloud sql instances describe "$INSTANCE" --format=json) || {
    echo "ERROR: gcloud command timed out or failed while describing instance $INSTANCE."
    exit 3
  }

  # Check if databaseFlags field exists
  HAS_FLAGS=$(echo "$JSON_OUTPUT" | jq '.settings.databaseFlags != null')

  if [ "$HAS_FLAGS" != "true" ]; then
    echo "Flag local_infile is not set (default OFF)."
    continue
  fi

  # Check for local_infile flag
  FLAG_VALUE=$(echo "$JSON_OUTPUT" | jq -r '
    .settings.databaseFlags[]?
    | select(.name == "local_infile")
    | .value')

  if [ -z "$FLAG_VALUE" ]; then
    echo "Flag local_infile is not set (default OFF)."
  elif [ "$FLAG_VALUE" == "off" ]; then
    echo "Flag local_infile is explicitly set to OFF."
  elif [ "$FLAG_VALUE" == "on" ]; then
    echo "NON-COMPLIANT: Flag local_infile is ON — this is a security risk!"
    NON_COMPLIANT_FOUND=1
  else
    echo "NON-COMPLIANT: Flag local_infile has unexpected value: $FLAG_VALUE"
    NON_COMPLIANT_FOUND=1
  fi
done

# Exit with code 2 if any non-compliant instance found
if [ $NON_COMPLIANT_FOUND -eq 1 ]; then
  exit 2
fi
