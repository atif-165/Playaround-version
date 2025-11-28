# ZEGO Video & Voice Call Configuration - COMPLETE ✅

## Configuration Status
Your ZEGO credentials have been successfully configured in the app!

**Configured Values:**
- **AppID**: `2049357064`
- **AppSign**: `315c8c1e77f05df9744db5e50c30ea23752d60bdeb5445653c1d757db42f6ac4`
- **Project**: playaround
- **Region**: Global
- **Status**: Testing

## What's Been Done
The credentials have been added to:
- `lib/config/video_call_config.dart` - Main configuration file
- `lib/core/config/video_call_config.dart` - Alternative config (for consistency)

## How to Use

### Running the App
Simply run your Flutter app as usual:
```bash
flutter run
```

The video and voice call features should now work in your Teams section!

### Testing Video/Voice Calls
1. Navigate to any team profile
2. Go to the "Team Communication" section
3. Click on "Video Call" or "Voice Call"
4. The call should start successfully

## Overriding Credentials (Optional)
If you need to use different credentials at build time, you can override them using:
```bash
flutter run --dart-define=ZEGO_APP_ID=your_app_id --dart-define=ZEGO_APP_SIGN=your_app_sign
```

## Troubleshooting

### If calls still don't work:
1. **Hot Restart**: Make sure to do a full hot restart (not just hot reload) after the configuration change
2. **Rebuild**: If hot restart doesn't work, try:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
3. **Check Permissions**: Ensure camera and microphone permissions are granted
4. **Check Network**: Ensure you have a stable internet connection

### Verify Configuration
The app will show an error screen if credentials are missing. If you see:
- "Video calling isn't configured yet" → Configuration issue
- Call screen loads → Configuration is working! ✅

## Additional ZEGO Information
- **WebSocket URL**: `wss://webliveroom2049357064-api.coolzcloud.com/ws`
- **ServerSecret**: `06cc359c8282603eb8f63cbd39da2126` (for backend use if needed)
- **CallbackSecret**: `315c8c1e77f05df9744db5e50c30ea23` (for backend use if needed)

## Next Steps
1. Test video calls between team members
2. Test voice calls
3. Test chat functionality (should work independently)
4. If everything works, you're all set! 🎉

---

**Note**: These credentials are now hardcoded in the config files. For production, consider:
- Using environment variables
- Using a secure configuration service
- Using `--dart-define` flags during CI/CD builds

