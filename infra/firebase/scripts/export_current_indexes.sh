#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$INFRA_DIR"

if [[ -z "${FIREBASE_PROJECT_ID:-}" ]]; then
  echo "FIREBASE_PROJECT_ID environment variable is required." >&2
  exit 1
fi

OUTPUT_FILE="${1:-backups/firestore.indexes.$(date +%Y%m%d%H%M%S).json}"
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "Exporting Firestore composite indexes for project ${FIREBASE_PROJECT_ID} to ${OUTPUT_FILE}"
firebase firestore:indexes --project "${FIREBASE_PROJECT_ID}" --format json > "${OUTPUT_FILE}"
echo "Done. Review the exported indexes and commit if changes are needed."

