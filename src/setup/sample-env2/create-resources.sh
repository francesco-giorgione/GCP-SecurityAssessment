#!/bin/bash

# Load environment variables
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found. Please create one with PROJECT_ID, REGION, ZONE, SQL_INSTANCE_NAME, and SQL_DB_VERSION."
  exit 1
fi

VM_NAMES=("vm-free-1" "vm-free-2")
BUCKET_NAMES=("bucket-free-1-unique1234567" "bucket-free-2-unique1234567")
FIRESTORE_ENABLED=0

# Set project
gcloud config set project "$PROJECT_ID" > /dev/null

create_resources() {
  echo "Creating resources..."

  echo "Creating e2-micro VMs..."
  for VM in "${VM_NAMES[@]}"; do
    if gcloud compute instances describe "$VM" --zone="$ZONE" &> /dev/null; then
      echo "VM $VM already exists. Skipping creation."
    else
      echo "Creating e2-micro VMs..."
for VM in "${VM_NAMES[@]}"; do
  if gcloud compute instances describe "$VM" --zone="$ZONE" &> /dev/null; then
    echo "VM $VM already exists. Skipping creation."
  else
    gcloud compute instances create "$VM" \
        --zone="$ZONE" \
        --machine-type=e2-micro \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB \
        --quiet
  fi
done

    fi
  done

  echo "Creating Cloud Storage buckets..."
  for BUCKET in "${BUCKET_NAMES[@]}"; do
    if gsutil ls -b "gs://$BUCKET" &> /dev/null; then
      echo "Bucket $BUCKET already exists. Skipping creation."
    else
      gcloud storage buckets create "gs://$BUCKET" \
        --location="$REGION" \
        --default-storage-class=STANDARD
    fi
  done

  if [[ $FIRESTORE_ENABLED -eq 0 ]]; then
    echo "Enabling and creating Firestore..."
    gcloud services enable firestore.googleapis.com

    if ! gcloud firestore databases describe &> /dev/null; then
      gcloud firestore databases create \
        --location="$REGION" \
        --type=firestore-native
    else
      echo "Firestore already exists. Skipping creation."
    fi
    FIRESTORE_ENABLED=1
  fi

  echo "Creating Cloud SQL instance..."
  gcloud services enable sqladmin.googleapis.com

  if gcloud sql instances describe "$SQL_INSTANCE_NAME" &> /dev/null; then
    echo "Cloud SQL instance already exists. Skipping creation."
  else
    gcloud sql instances create "$SQL_INSTANCE_NAME" \
      --database-version="$SQL_DB_VERSION" \
      --tier=db-f1-micro \
      --region="$REGION" \
      --storage-type=SSD \
      --database-flags=local_infile=off \
      --storage-size=10GB \
      --quiet
  fi

  echo "Resource creation complete."
}

stop_resources() {
  echo "Stopping VMs..."
  for VM in "${VM_NAMES[@]}"; do
    gcloud compute instances stop "$VM" --zone="$ZONE" --quiet
  done
  echo "VMs stopped."
}

delete_resources() {
  echo "Deleting resources..."

  for VM in "${VM_NAMES[@]}"; do
    gcloud compute instances delete "$VM" --zone="$ZONE" --quiet || echo "VM $VM not found."
  done

  for BUCKET in "${BUCKET_NAMES[@]}"; do
    gsutil -m rm -r "gs://$BUCKET" || echo "Bucket $BUCKET not found."
  done

  echo "Firestore databases cannot be deleted via CLI. Please delete manually from the console."
  echo "Cloud SQL instance cannot be automatically deleted. Run:"
  echo "gcloud sql instances delete $SQL_INSTANCE_NAME --quiet"
  echo "Deletion complete."
}

start_resources() {
  echo "Starting VMs..."
  for VM in "${VM_NAMES[@]}"; do
    gcloud compute instances start "$VM" --zone="$ZONE" --quiet
  done
  echo "VMs started."
}


case "$1" in
  --create)
    create_resources
    ;;
  --stop)
    stop_resources
    ;;
  --delete)
    delete_resources
    ;;
  --start)
    start_resources
    ;;
  *)

    echo "Usage: $0 [--create | --stop | --delete | --start]"
    ;;
esac
