#!/bin/bash

if [[ -z "$1" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 1
fi

PROJECT_ID="$1"

echo "Checking for risky IAM role assignments at project level in project: $PROJECT_ID"
echo "--------------------------------------------------------------------------"

# Retrieve the full IAM policy for the project
IAM_POLICY=$(gcloud projects get-iam-policy "$PROJECT_ID" --format=json)

NON_COMPLIANT=0

# Check for roles/iam.serviceAccountUser assigned at project level
SA_USER_BINDING=$(echo "$IAM_POLICY" | jq -r '.bindings[] | select(.role=="roles/iam.serviceAccountUser")')

if [[ -n "$SA_USER_BINDING" ]]; then
  echo "Problem detected: The role 'roles/iam.serviceAccountUser' is assigned at the project level."
  echo "This gives users the ability to act as any service account in the project, violating the principle of least privilege."
  echo "Role binding:"
  echo "$SA_USER_BINDING" | jq
  NON_COMPLIANT=1
fi

# Check for roles/iam.serviceAccountTokenCreator assigned at project level
SA_TOKEN_CREATOR_BINDING=$(echo "$IAM_POLICY" | jq -r '.bindings[] | select(.role=="roles/iam.serviceAccountTokenCreator")')

if [[ -n "$SA_TOKEN_CREATOR_BINDING" ]]; then
  echo "Problem detected: The role 'roles/iam.serviceAccountTokenCreator' is assigned at the project level."
  echo "This allows users to impersonate any service account in the project, potentially escalating privileges."
  echo "Role binding:"
  echo "$SA_TOKEN_CREATOR_BINDING" | jq
  NON_COMPLIANT=1
fi

if [[ "$NON_COMPLIANT" -eq 0 ]]; then
  echo "No risky service account roles found at project level. Project is compliant."
else
  echo "One or more risky IAM roles are assigned at project level. Manual review and remediation are recommended."
  exit 2
fi