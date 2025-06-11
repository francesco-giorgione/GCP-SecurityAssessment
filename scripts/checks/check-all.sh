#!/bin/bash

# Get arguments
PROJECT_ID="$1"
AUTHORIZED_DOMAIN="$2"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: You must specify a project ID as the first argument."
  echo "Usage: ./check-all.sh <PROJECT_ID> [AUTHORIZED_DOMAIN]"
  exit 1
fi

# List of scripts to execute
SCRIPTS=("1-1.sh" "1-4.sh" "1-5.sh" "1-6.sh" "2-1.sh" "2-3.sh" "3-1.sh" "4-6.sh" "4-9.sh" "6-1-3.sh")

# Check if 1-1.sh is among the scripts, and if so, require AUTHORIZED_DOMAIN
NEEDS_AUTH_DOMAIN=false
for script in "${SCRIPTS[@]}"; do
  if [[ "$script" == "1-1.sh" ]]; then
    NEEDS_AUTH_DOMAIN=true
    break
  fi
done

if $NEEDS_AUTH_DOMAIN && [ -z "$AUTHORIZED_DOMAIN" ]; then
  echo "Error: You must specify an authorized domain as the second argument for control 1.1."
  echo "Usage: ./check-all.sh <PROJECT_ID> <AUTHORIZED_DOMAIN>"
  exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Generate a timestamped log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="logs/check-all_${PROJECT_ID}_${TIMESTAMP}.log"

# Write header to log file
{
  echo "===== GCP Security Checks Log ====="
  echo "Project: $PROJECT_ID"
  if $NEEDS_AUTH_DOMAIN; then
    echo "Authorized domain: $AUTHORIZED_DOMAIN"
  fi
  echo "Start time: $(date)"
  echo
} > "$LOGFILE"

# Execute each script and log the output
for SCRIPT in "${SCRIPTS[@]}"; do
  echo "Running: $SCRIPT for project $PROJECT_ID..."

  {
    echo
    echo "================================================================================"
    echo "Running script: $SCRIPT for project: $PROJECT_ID"
    echo "================================================================================"
    echo

    if [[ -x "$SCRIPT" ]]; then
      if [[ "$SCRIPT" == "1-1.sh" ]]; then
        ./"$SCRIPT" --project "$PROJECT_ID" "$AUTHORIZED_DOMAIN"
      else
        ./"$SCRIPT" "$PROJECT_ID"
      fi
    else
      echo "Warning: Script $SCRIPT not found or not executable."
    fi

    echo
    echo "--------------------------------------------------------------------------------"
    echo "End of script: $SCRIPT"
    echo "--------------------------------------------------------------------------------"
    echo
  } >> "$LOGFILE" 2>&1
done

# Final log message
{
  echo "All checks completed."
  echo "End time: $(date)"
} >> "$LOGFILE"

echo "All output has been saved to: $LOGFILE"
