#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$INFRA_DIR"

if [[ -z "${FIREBASE_PROJECT_ID:-}" ]]; then
  echo "FIREBASE_PROJECT_ID environment variable is required." >&2
  echo "Export FIREBASE_PROJECT_ID or pass it inline, e.g. FIREBASE_PROJECT_ID=my-project ./scripts/deploy_indexes.sh" >&2
  exit 1
fi

echo "Deploying Firestore composite indexes to project ${FIREBASE_PROJECT_ID}..."
firebase deploy --project "${FIREBASE_PROJECT_ID}" --only firestore:indexes --non-interactive
echo "Firestore indexes deployed."

