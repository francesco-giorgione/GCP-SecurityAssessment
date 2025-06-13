#!/bin/bash

# Exit on any error
set -e

# Require project ID as input
if [ -z "$1" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"
OUTPUT_FILE="updated-policy.json"

echo "Fetching current IAM policy for project '$PROJECT_ID'..."
gcloud projects get-iam-policy "$PROJECT_ID" --format=json > current_policy.json

# Strip down to accepted fields: bindings and (eventually) auditConfigs
jq '{bindings: .bindings}' current_policy.json > "$OUTPUT_FILE"

# Add the auditConfigs section
jq '. + {
  auditConfigs: [
    {
      service: "allServices",
      auditLogConfigs: [
        { logType: "ADMIN_READ" },
        {
          logType: "DATA_WRITE",
          exemptedMembers: ["user:f.giorgione4@studenti.unisa.it"]
        },
        { logType: "DATA_READ" }
      ]
    }
  ]
}' "$OUTPUT_FILE" > tmp.json && mv tmp.json "$OUTPUT_FILE"

echo "Updated IAM policy prepared in $OUTPUT_FILE:"
echo "--------------------------------------------"
cat "$OUTPUT_FILE"
echo "--------------------------------------------"

# Apply update
gcloud projects set-iam-policy "$PROJECT_ID" "$OUTPUT_FILE"
echo "Policy successfully applied to project '$PROJECT_ID'."