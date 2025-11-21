# Team Data Validation Script

This script helps identify and optionally fix corrupted team data in your Firestore database.

## Quick Start

### Option 1: Run from Admin Screen (Recommended)

Add a button in your admin/developer screen:

```dart
import 'package:playaround/modules/team/scripts/validate_team_data.dart';

ElevatedButton(
  onPressed: () async {
    final validator = TeamDataValidator();
    
    // Just check (dry run)
    await validator.runFullValidation(autoFix: false);
    
    // Show results in console/logs
  },
  child: Text('Validate Team Data'),
),

ElevatedButton(
  onPressed: () async {
    final validator = TeamDataValidator();
    
    // Check AND fix
    await validator.runFullValidation(autoFix: true);
  },
  child: Text('Fix Team Data Issues'),
),
```

### Option 2: Run as Standalone Script

Create a temporary file `lib/temp_validate_teams.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:playaround/firebase_options.dart';
import 'package:playaround/modules/team/scripts/validate_team_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final validator = TeamDataValidator();
  
  // Dry run - just check for issues
  print('🔍 Running validation (dry run)...\n');
  await validator.runFullValidation(autoFix: false);
  
  // Uncomment below to actually fix the issues
  // print('🔧 Running validation with auto-fix...\n');
  // await validator.runFullValidation(autoFix: true);
  
  exit(0);
}
```

Then run it:

```bash
flutter run lib/temp_validate_teams.dart
```

### Option 3: From Existing Admin Panel

If you have an admin testing screen, add this function:

```dart
Future<void> _validateTeamData() async {
  final validator = TeamDataValidator();
  
  setState(() => _isValidating = true);
  
  try {
    final report = await validator.validateAllTeams(autoFix: false);
    
    // Show results in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Validation Report'),
        content: SingleChildScrollView(
          child: Text(report.toString()),
        ),
        actions: [
          if (report.teamsWithIssues > 0)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Run with autoFix
                await validator.validateAllTeams(autoFix: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fixed ${report.teamsWithIssues} teams')),
                );
              },
              child: Text('Fix Issues'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  } finally {
    setState(() => _isValidating = false);
  }
}
```

## What the Script Checks

### Teams Collection
- ✅ Required fields: `name`, `nameLowercase`, `createdBy`, `sportType`
- ✅ Players array: Each player must have valid `id` and `name`
- ✅ Coaches array: Each coach must have valid `id` and `name`

### Join Requests Collection
- ✅ Required fields: `teamId`, `userId`, `userName`, `requestedRole`

### Team Matches Collection
- ✅ Required fields: `homeTeamId`, `awayTeamId`
- ✅ TeamScore objects: Each must have valid `teamId` and `teamName`

## What Auto-Fix Does

When `autoFix: true`:

### For Teams:
- Sets default values for missing required fields
- Filters out invalid players/coaches from arrays
- Updates `nameLowercase` and `nameInitial` if missing

### For Join Requests:
- **Deletes** requests with critical missing data (safer than corrupting with dummy data)

### For Team Matches:
- **Logs** for manual review (matches are too critical to auto-fix)

## Sample Output

```
🔍 Starting full team data validation...

Auto-fix: DISABLED

============================================================

📋 VALIDATING TEAMS

📊 Validating 15 teams...

❌ Team abc123: Missing "createdBy" field
❌ Team def456: 2 players with null/empty id or name (indices: 3, 5)

📊 VALIDATION REPORT
============================================================
✅ Valid teams: 13
❌ Teams with issues: 2

DETAILED ISSUES:

Team: abc123
  ❌ Missing or empty "createdBy" field

Team: def456
  ❌ 2 players with null/empty id or name (indices: 3, 5)

============================================================

✅ Validation complete!
```

## Safety

- The script runs read operations by default (`autoFix: false`)
- You can review all issues before fixing
- Backups are recommended before running with `autoFix: true`
- Invalid join requests are deleted (not worth keeping corrupted data)
- Matches with issues are flagged for manual review

## When to Run

1. **After the null safety fix** - to clean up existing bad data
2. **After data migration** - to ensure data integrity
3. **Periodically** - as part of database maintenance
4. **When users report errors** - to identify specific issues

## Tips

1. Always run with `autoFix: false` first to see what will be changed
2. Check your Firebase Console after running to verify changes
3. Consider adding this as a periodic admin task
4. Monitor the logs for patterns (e.g., many teams from same time period having issues)

## Firebase Console Alternative

You can also manually check data in Firebase Console:
1. Go to Firestore Database
2. Navigate to `teams` collection
3. Look for documents with:
   - Null values in `name`, `createdBy`, `sportType`
   - Players/coaches arrays with incomplete entries
   - Missing `nameLowercase` field

## Questions?

If you encounter issues running the script, check:
- Firebase is properly initialized
- You have proper permissions to read/write Firestore
- The script is imported correctly
- Console/debug logs for detailed error messages

