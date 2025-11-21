# Firebase Core Infra Recovery

This directory recreates the minimum Firebase backbone (Auth, Firestore, Storage, Messaging) required for local development and automated reprovisioning after the index loss event.

## Prerequisites
- Install the Firebase CLI (`npm install -g firebase-tools`).
- Install `firebase-admin` locally for the mock seeding script (`npm install firebase-admin`).
- Authenticate (`firebase login`) and select the target project, or set `FIREBASE_PROJECT_ID` before running scripts.
- For emulator use, export `FIRESTORE_EMULATOR_HOST=localhost:8080`, `FIREBASE_AUTH_EMULATOR_HOST=localhost:9099`, `FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199`.

## Deployment Workflow
1. `cd infra/firebase`
2. `FIREBASE_PROJECT_ID=my-project ./scripts/deploy_indexes.sh`
3. `FIREBASE_PROJECT_ID=my-project ./scripts/export_current_indexes.sh` (optional backup)
4. `firebase deploy --project $FIREBASE_PROJECT_ID --only firestore:rules,storage`

### Emulator Validation
- `firebase emulators:start --only firestore,auth,storage`
- `node mocks/create_sample_docs.js`
- Use the Emulator UI to confirm seeded collections and to verify security rules (attempt unauthorized writes).

## Composite Index Coverage
The deployed indexes were recreated from historical query logs and cover the following screens:

- **Bookings board** – `bookings` by `venueId asc + startTime asc`, `bookings` by `userId asc + startTime desc`, `bookings` by `status asc + startTime asc`
- **Coach discovery** – `users` role sorts (`role asc + lastActiveAt desc`, `role asc + rating desc`), `coachListings` filters (`sportId asc + pricePerHour asc`, `sportId asc + rating desc`)
- **Venue management** – `venues` (`city asc + rating desc`, `managerId asc + status asc`)
- **Session listings** – `listings` (`venueId asc + startsAt asc`, `coachId asc + startsAt asc`)
- **Tournaments & leaderboard** – `matches` (`tournamentId asc + startTime asc`), `leaderboardEntries` (`tournamentId asc + score desc`, `tournamentId asc + wins desc`), `teams` (`clubId asc + name asc`), `teamMembers` (`teamId asc + role asc`), `tournaments` (`seasonId asc + startDate desc`)
- **Messaging** – `messageThreads` (`participants array-contains + updatedAt desc`), `messages` (`threadId asc + createdAt asc`), `notifications` (`userId asc + createdAt desc`)
- **Community feed** – `posts` (`tags array-contains + publishedAt desc`)

See `indexes_recreated_report.json` for a machine-readable mapping of screens to index names.

### Example index snippet
```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "venueId", "order": "ASCENDING" },
    { "fieldPath": "startTime", "order": "ASCENDING" }
  ]
}
```
Used by the bookings board to list upcoming reservations per venue sorted by start time.

## Security Expectations
- **`firestore.rules`** enforces role-based access. Admin collections (`adminReports`, `systemConfigs`) are admin-only. Booking updates are restricted to the booking owner or admins.
- **`storage.rules`** allow only specific MIME types (JPEG, PNG, WEBP images and MP4/QuickTime video) with a 15 MB limit, blocking uploads such as `.exe`.
- Run the manual checks outlined in “Testing & Recovery Checks” after redeploying.

## Index Recovery Checklist
1. Run `./scripts/export_current_indexes.sh` against any surviving project to archive remaining indexes.
2. Compare `backups/*.json` against `firestore.indexes.json`; merge any missing definitions.
3. Ask product owner to verify critical screens (search, leaderboard, bookings, tournaments, messaging) and report queries that still fail with missing-index errors.
4. Document any new queries and append matching index definitions to `firestore.indexes.json`.
5. Re-run `./scripts/deploy_indexes.sh` after changes.

## Testing & Recovery Checks
- `cd infra/firebase && ./scripts/deploy_indexes.sh`
- `node mocks/create_sample_docs.js`
- `firebase emulators:start --only firestore,auth,storage`
- Attempt to write to `/adminReports` as a non-admin → expect “PERMISSION_DENIED”.
- Attempt to upload `malware.exe` to Storage → expect rejection because of MIME mismatch.

## One-line Index Backup
```bash
FIREBASE_PROJECT_ID=my-project firebase firestore:indexes --project "$FIREBASE_PROJECT_ID" --format json > backups/firestore.indexes.$(date +%Y%m%d%H%M%S).json
```

## Notes
- `firebase.json` keeps the `${FIREBASE_PROJECT_ID}` placeholder; scripts set the actual project via CLI flags so CI environments can substitute automatically.
- Emulator-first validation is expected when cloud access is unavailable.
- Track any additional indexes in `indexes_recreated_report.json` so stakeholders can confirm coverage before production rollout.

