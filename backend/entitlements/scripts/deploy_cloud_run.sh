#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${1:-}"
REGION="${2:-}"
SERVICE_NAME="${3:-wealth-dial-entitlements}"

if [[ -z "${PROJECT_ID}" || -z "${REGION}" ]]; then
  echo "Usage: ./deploy_cloud_run.sh <PROJECT_ID> <REGION> [SERVICE_NAME]"
  exit 1
fi

IMAGE="gcr.io/${PROJECT_ID}/${SERVICE_NAME}:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Deploying ${SERVICE_NAME} to Cloud Run..."
echo "Project: ${PROJECT_ID}"
echo "Region:  ${REGION}"
echo "Image:   ${IMAGE}"

gcloud config set project "${PROJECT_ID}" >/dev/null

(
  cd "${SERVICE_ROOT}"
  gcloud builds submit --tag "${IMAGE}" .
)

gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "GOOGLE_PLAY_PACKAGE_NAME=com.wealthdial.app,GOOGLE_PLAY_LIFETIME_PRODUCT_IDS=founder_lifetime,ALLOW_TOKEN_TRANSFER=false" \
  --update-secrets "ENTITLEMENT_API_KEY=ENTITLEMENT_API_KEY:latest"

URL="$(gcloud run services describe "${SERVICE_NAME}" --region "${REGION}" --format "value(status.url)")"
echo ""
echo "Deployment complete."
echo "Service URL: ${URL}"
echo ""
echo "Next step: use this URL for Flutter --dart-define ENTITLEMENT_API_BASE_URL."
