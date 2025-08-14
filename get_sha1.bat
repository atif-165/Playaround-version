@echo off
echo Getting SHA-1 fingerprint for Firebase configuration...
echo.

echo Debug SHA-1 fingerprint:
cd android
gradlew signingReport
echo.

echo.
echo Copy the SHA1 fingerprint from the debug variant above and add it to your Firebase project:
echo 1. Go to Firebase Console: https://console.firebase.google.com/
echo 2. Select your project: playaround-6556e
echo 3. Go to Project Settings
echo 4. Select your Android app
echo 5. Add the SHA-1 fingerprint in the "SHA certificate fingerprints" section
echo.
pause
