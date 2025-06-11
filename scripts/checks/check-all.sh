#!/bin/bash

# Project ID passed as argument
PROJECT_ID="$1"

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: You must specify a project ID as the first argument."
  echo "Example: ./check-all.sh my-gcp-project"
  exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Generate a timestamped log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="logs/check-all_${PROJECT_ID}_${TIMESTAMP}.log"

# List of scripts to execute
SCRIPTS=("1-1.sh" "1-4.sh" "1-5.sh" "1-6.sh" "2-1.sh" "2-3.sh" "3-1.sh")

# Write header to log file
{
  echo "===== GCP Security Checks Log ====="
  echo "Project: $PROJECT_ID"
  echo "Start time: $(date)"
  echo
} > "$LOGFILE"

# Execute each script and log the output
for SCRIPT in "${SCRIPTS[@]}"; do
  echo "🔄 Running: $SCRIPT for project $PROJECT_ID..."

  {
    echo
    echo "================================================================================"
    echo "🔍 Running script: $SCRIPT for project: $PROJECT_ID"
    echo "================================================================================"
    echo

    if [[ -x "$SCRIPT" ]]; then
      ./"$SCRIPT" "$PROJECT_ID"
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
