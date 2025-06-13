#!/bin/bash

# Exit on any error
set -e

# Load environment variables from .env
if [ ! -f .env ]; then
  echo "Error: .env file not found in the current directory."
  exit 1
fi

# Export environment variables
set -a
source .env
set +a

# Check if PROJECT_ID is set
if [[ -z "$PROJECT_ID" ]]; then
  echo "Error: PROJECT_ID is not defined in the .env file."
  exit 1
fi

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
echo "✅ Policy successfully applied to project '$PROJECT_ID'."
