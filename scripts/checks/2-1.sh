#!/bin/bash

# Usage check
if [[ -z "$1" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

# Fetch IAM policy as JSON
POLICY_JSON=$(gcloud projects get-iam-policy "$PROJECT_ID" --format=json)

# Extract auditConfigs
AUDIT_CONFIGS=$(echo "$POLICY_JSON" | jq '.auditConfigs // empty')

if [[ -z "$AUDIT_CONFIGS" ]]; then
  echo "Missing auditConfigs section in IAM policy."
  exit 2
fi

# Filter only the entry for allServices
ALL_SERVICES_CONFIG=$(echo "$AUDIT_CONFIGS" | jq '.[] | select(.service == "allServices")')

if [[ -z "$ALL_SERVICES_CONFIG" ]]; then
  echo "No auditConfigs entry for 'allServices'."
  exit 3
fi

# Required log types
REQUIRED_LOGTYPES=("ADMIN_READ" "DATA_WRITE" "DATA_READ")

# Validate each logType
for LOGTYPE in "${REQUIRED_LOGTYPES[@]}"; do
  MATCH=$(echo "$ALL_SERVICES_CONFIG" | jq -e --arg LOGTYPE "$LOGTYPE" '.auditLogConfigs[]? | select(.logType == $LOGTYPE)')
  if [[ -z "$MATCH" ]]; then
    echo "Missing logType: $LOGTYPE in allServices audit config."
    exit 4
  fi
done

# Check that there are no exemptedMembers
EXEMPTED=$(echo "$ALL_SERVICES_CONFIG" | jq '.auditLogConfigs[]?.exemptedMembers? // empty')

if [[ -n "$EXEMPTED" ]]; then
  echo "Found exemptedMembers in audit config, which is not allowed:"
  echo "$EXEMPTED"
  exit 5
fi

echo "Audit logging configuration is fully compliant with CIS benchmark."