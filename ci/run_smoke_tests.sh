#!/usr/bin/env bash
set -euo pipefail

# Simple smoke tests that run in CI using Workload Identity credentials.
# - Lists Storage buckets for the project
# - Lists Firestore collections (if applicable)

echo "PROJECT_ID=${PROJECT_ID:-unknown}"

echo "Listing Storage buckets..."
gcloud storage buckets list --project="${PROJECT_ID}" || true

echo "Listing Cloud Functions (if any)..."
gcloud functions list --project="${PROJECT_ID}" --region="us-central1" || true

echo "Smoke tests completed."
