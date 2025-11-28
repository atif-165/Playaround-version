# Commands to Fetch Venues from Firestore

## Option 1: Using Firebase Console (Easiest)
1. Go to: https://console.firebase.google.com/project/playaround-6556e/firestore/data
2. Click on the `venues` collection
3. You should see all 13 documents listed there

## Option 2: Test in Your Flutter App (Recommended)
The test function is already added to your code. Just rebuild and run your app, then:
1. Open the "Discover Premium Venues" screen
2. Check the console logs - you'll see:
   ```
   🧪 TEST: Fetching venues directly...
   🧪 TEST: Fetched X documents
   ```

## Option 2: Using Firebase Console
1. Go to: https://console.firebase.google.com/project/playaround-6556e/firestore
2. Navigate to the `venues` collection
3. You should see all 13 documents there

## Option 3: Test in Your Flutter App
Add this temporary code to test in your app:

```dart
// Add this to your venue_discovery_screen.dart in _loadVenues method
final testSnapshot = await FirebaseFirestore.instance.collection('venues').get();
print('🔍 Direct test query: ${testSnapshot.docs.length} documents');
for (var doc in testSnapshot.docs) {
  print('  - ${doc.id}: ${doc.data()['title'] ?? doc.data()['name']}');
}
```

## Option 4: Using curl (Firebase REST API)
You'll need your Firebase project API key and a valid access token.

## Option 5: Quick Test Script
Run the test_fetch_venues.dart file I created (you'll need to configure Firebase first).

