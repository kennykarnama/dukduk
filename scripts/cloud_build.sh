#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

GCS_BUCKET="gs://kennyf/dukduk-artifacts"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts"

echo "=== Submitting build to Google Cloud Build (e2-highcpu-32: 32 vCPUs) ==="
echo "Project: kennyx-500614"
echo "Target Artifacts Destination: ${GCS_BUCKET}"
echo ""

gcloud builds submit --config=cloudbuild.yaml --machine-type=e2-highcpu-32 .

echo ""
echo "=== Downloading artifacts from GCS ==="
mkdir -p "${ARTIFACTS_DIR}"
gcloud storage cp -r "${GCS_BUCKET}/*" "${ARTIFACTS_DIR}/" || true

# Flatten if artifacts was nested under artifacts/artifacts or artifacts/linux-amd64
if [ -d "${ARTIFACTS_DIR}/artifacts" ]; then
  mv "${ARTIFACTS_DIR}/artifacts/"* "${ARTIFACTS_DIR}/" 2>/dev/null || true
  rm -rf "${ARTIFACTS_DIR}/artifacts"
fi
if [ -d "${ARTIFACTS_DIR}/linux-amd64" ]; then
  mv "${ARTIFACTS_DIR}/linux-amd64/"* "${ARTIFACTS_DIR}/" 2>/dev/null || true
  rm -rf "${ARTIFACTS_DIR}/linux-amd64"
fi
rm -f "${ARTIFACTS_DIR}"/*.json 2>/dev/null || true
chmod +x "${ARTIFACTS_DIR}"/fincent-api-* 2>/dev/null || true

echo ""
echo "=== Downloaded Artifacts in ${ARTIFACTS_DIR} ==="
ls -lh "${ARTIFACTS_DIR}"
echo ""
echo "✓ Done! Build completed in Google Cloud without laptop load."
