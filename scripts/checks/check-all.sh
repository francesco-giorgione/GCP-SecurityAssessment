#!/bin/bash

# Get arguments
PROJECT_ID="$1"
AUTHORIZED_DOMAIN="$2"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: You must specify a project ID as the first argument."
  echo "Usage: ./check-all.sh <PROJECT_ID> <AUTHORIZED_DOMAIN>"
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
# Create the insights directory if it doesn't exist
mkdir -p insights

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


# Full path of the output HTML report
REPORT_FILE="insights/report_${PROJECT_ID}_${TIMESTAMP}.html"

# Start of the HTML file
echo "<!DOCTYPE html>
<html>
<head>
  <title>Script Execution Report</title>
  <style>
    body { font-family: Arial, sans-serif; }
    table { border-collapse: collapse; width: 60%; margin: 20px auto; }
    th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
    th { background-color: #f2f2f2; }
    .status-0 { background-color: #c8e6c9; }   /* light green */
    .status-1 { background-color: #fff9c4; }   /* light yellow */
    .status-2 { background-color: #ffcdd2; }   /* light red */
  </style>
</head>
<body>
<h2 style=\"text-align:center\">Script Execution Report</h2>
<table>
  <tr><th>Script</th><th>Status</th></tr>" > "$REPORT_FILE"




# Execute each script and log the output and exit code
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
      EXIT_CODE=$?
      echo
      echo "Script $SCRIPT exited with code: $EXIT_CODE"
      echo
    else
      echo "Warning: Script $SCRIPT not found or not executable."
      EXIT_CODE=127
      echo "Script $SCRIPT exited with code: $EXIT_CODE"
    fi

    echo
    echo "--------------------------------------------------------------------------------"
    echo "End of script: $SCRIPT"
    echo "--------------------------------------------------------------------------------"
    echo
  } >> "$LOGFILE" 2>&1

  case $EXIT_CODE in
    0) status_text="OK! All settings are compliant!" ;;
    1) status_text="Execution failed. Try again!" ;;
    2) status_text="Warning: elements of non-compliance detected!" ;;
  esac
  echo "<tr class=\"status-$EXIT_CODE\"><td>$SCRIPT</td><td>$status_text</td></tr>" >> "$REPORT_FILE"

  echo "Script $SCRIPT exited with code: $EXIT_CODE"
done


# Final log message
{
  echo "All checks completed."
  echo "End time: $(date)"
} >> "$LOGFILE"

# End of the HTML file
echo "</table></body></html>" >> "$REPORT_FILE"

echo "All output has been saved to: $LOGFILE"
echo "Report generated: $REPORT_FILE"
