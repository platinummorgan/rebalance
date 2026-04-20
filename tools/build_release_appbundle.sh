#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFINES_FILE="${REPO_ROOT}/config/dart_defines.production.json"
DEFINES_TEMPLATE="${REPO_ROOT}/config/dart_defines.production.example.json"

if [[ ! -f "${DEFINES_FILE}" ]]; then
  echo "Missing required file: ${DEFINES_FILE}"
  echo ""
  echo "Create it from template:"
  echo "  cp \"${DEFINES_TEMPLATE}\" \"${DEFINES_FILE}\""
  echo "Then set values for ENTITLEMENT_API_BASE_URL and ENTITLEMENT_API_KEY."
  exit 1
fi

cd "${REPO_ROOT}"

flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

flutter build appbundle --release \
  --dart-define-from-file="${DEFINES_FILE}" \
  --obfuscate \
  --split-debug-info=build/symbols/

echo ""
echo "Build complete:"
echo "  build/app/outputs/bundle/release/app-release.aab"
