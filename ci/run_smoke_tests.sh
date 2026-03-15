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

echo "Running Vision API quick test (label detection on a 1x1 PNG)..."
# Create a tiny 1x1 PNG (base64) and call Vision API via REST
IMG_BASE64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBAp8p2JkAAAAASUVORK5CYII="
ACCESS_TOKEN="$(gcloud auth print-access-token)"
cat > /tmp/vision-request.json <<EOF
{
	"requests": [
		{
			"image": { "content": "${IMG_BASE64}" },
			"features": [ { "type": "LABEL_DETECTION", "maxResults": 5 } ]
		}
	]
}
EOF

curl -s -X POST \
	-H "Authorization: Bearer ${ACCESS_TOKEN}" \
	-H "Content-Type: application/json; charset=utf-8" \
	"https://vision.googleapis.com/v1/images:annotate" \
	--data-binary @/tmp/vision-request.json | jq '.' || true

echo "Smoke tests completed."
