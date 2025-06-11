#!/bin/bash

# Check input
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Set the active project
gcloud config set project "$PROJECT_ID" >/dev/null

# Retrieve list of MySQL instances
INSTANCES=$(gcloud sql instances list \
  --filter='DATABASE_VERSION:MYSQL*' \
  --format='value(NAME)')

if [ -z "$INSTANCES" ]; then
  echo "No MySQL instances found in project $PROJECT_ID"
  exit 0
fi

for INSTANCE in $INSTANCES; do
  echo "Checking instance: $INSTANCE"

  JSON_OUTPUT=$(gcloud sql instances describe "$INSTANCE" --format=json)

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
  else
    echo "NON-COMPLIANT: Flag local_infile has unexpected value: $FLAG_VALUE"
  fi
done
