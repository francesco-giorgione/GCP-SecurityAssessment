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

mkdir -p logs
mkdir -p insights

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="logs/check-all_${PROJECT_ID}_${TIMESTAMP}.log"
REPORT_FILE="insights/report_${PROJECT_ID}_${TIMESTAMP}.html"

# Initialize category stats
declare -A TOTAL_SCRIPTS
declare -A FAILED_SCRIPTS

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

# Start of HTML report
echo "<!DOCTYPE html>
<html>
<head>
  <title>Script Execution Report</title>
  <style>
    body { font-family: Arial, sans-serif; }
    table { border-collapse: collapse; width: 80%; margin: 20px auto; }
    th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
    th { background-color: #f2f2f2; }
    .status-0 { background-color: #c8e6c9; }
    .status-1 { background-color: #fff9c4; }
    .status-2 { background-color: #ffcdd2; }
    .status-3 { background-color: #fff9c4; }
  </style>
</head>
<body>
<h2 style=\"text-align:center\">Script Execution Report</h2>
<table>
  <tr><th>Script</th><th>Status</th></tr>" > "$REPORT_FILE"

# Run scripts
for SCRIPT in "${SCRIPTS[@]}"; do
  CATEGORY="${SCRIPT%%-*}"  # extract 'x' from 'x-<other>.sh'
  ((TOTAL_SCRIPTS[$CATEGORY]++))

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

  # Count failed scripts (exit code != 0)
  if [[ $EXIT_CODE -ne 0 ]]; then
    ((FAILED_SCRIPTS[$CATEGORY]++))
  fi

  case $EXIT_CODE in
    0) status_text="OK! All settings are compliant!" ;;
    1) status_text="Execution failed. Try again!" ;;
    2) status_text="Warning: elements of non-compliance detected!" ;;
    3) status_text="Execution failed due to free GCP API rate limitation. Try again!" ;;
    *) status_text="Unknown or script not found (exit code $EXIT_CODE)" ;;
  esac

  echo "<tr class=\"status-$EXIT_CODE\"><td>$SCRIPT</td><td>$status_text</td></tr>" >> "$REPORT_FILE"

  echo "Script $SCRIPT exited with code: $EXIT_CODE"
done

# End of individual script results table
echo "</table>" >> "$REPORT_FILE"

# Add summary per category
echo "</table>" >> "$REPORT_FILE"

CHART_JS=""
CHART_DATA_INIT=""

echo "<h2 style=\"text-align:center\">Category Summary</h2>
<table>
  <tr><th>Category</th><th>Total Checks</th><th>Non-Compliant</th><th>Non-Compliance Rate (%)</th><th>Graph</th></tr>" >> "$REPORT_FILE"

for CATEGORY in "${!TOTAL_SCRIPTS[@]}"; do
  TOTAL=${TOTAL_SCRIPTS[$CATEGORY]}
  FAILED=${FAILED_SCRIPTS[$CATEGORY]:-0}
  RATE=$(awk "BEGIN {printf \"%.2f\", ($FAILED/$TOTAL)*100}")

  echo "<tr>
          <td>$CATEGORY</td>
          <td>$TOTAL</td>
          <td>$FAILED</td>
          <td>$RATE%</td>
          <td><canvas id=\"chart_$CATEGORY\" width=\"300\" height=\"100\"></canvas></td>
        </tr>" >> "$REPORT_FILE"

  CHART_DATA_INIT+="
    new Chart(document.getElementById('chart_$CATEGORY'), {
      type: 'bar',
      data: {
        labels: ['Compliant', 'Non-Compliant'],
        datasets: [{
          label: 'Checks',
          data: [$(($TOTAL - $FAILED)), $FAILED],
          backgroundColor: ['#4caf50', '#f44336']
        }]
      },
      options: {
        indexAxis: 'y',
        plugins: {
          legend: { display: false },
          title: { display: true, text: 'Category $CATEGORY' }
        },
        scales: {
          x: { beginAtZero: true, max: $TOTAL }
        }
      }
    });
  "
done

echo "</table>" >> "$REPORT_FILE"

echo "
<script src=\"https://cdn.jsdelivr.net/npm/chart.js\"></script>
<script>
  window.onload = function() {
    $CHART_DATA_INIT
  };
</script>
</body>
</html>" >> "$REPORT_FILE"


# Final log entry
{
  echo "All checks completed."
  echo "End time: $(date)"
} >> "$LOGFILE"

echo "All output has been saved to: $LOGFILE"
echo "Report generated: $REPORT_FILE"
