# Firebase Security Rules Setup

This document explains how to deploy the Firebase security rules for the team and tournament management features.

## Overview

The security rules in `firestore_security_rules.rules` provide comprehensive access control for:

- **Teams Collection**: Controls who can create, read, update, and delete teams
- **Team Join Requests Collection**: Manages access to join request operations
- **Tournaments Collection**: Controls tournament creation and management
- **Tournament Registrations Collection**: Manages tournament registration access

## Key Security Features

### Teams Security
- **Public teams**: Readable by all authenticated users
- **Private teams**: Only readable by team members
- **Team creation**: Only by authenticated users who set themselves as owner
- **Team updates**: Only by team owners or captains
- **Team deletion**: Only by team owners

### Team Join Requests Security
- **Read access**: Requesters and team owners/captains only
- **Create requests**: Only by authenticated users for themselves
- **Approve/reject**: Only by team owners or captains
- **Cancel requests**: Only by the original requester

### Tournaments Security
- **Public tournaments**: Readable by all authenticated users
- **Private tournaments**: Only readable by organizers
- **Tournament creation**: Only by authenticated users who set themselves as organizer
- **Tournament updates**: Only by tournament organizers
- **Tournament deletion**: Only by tournament organizers

### Tournament Registrations Security
- **Read access**: Team registrants and tournament organizers only
- **Create registrations**: Only by authenticated users for their own teams
- **Approve/reject**: Only by tournament organizers
- **Withdraw registrations**: Only by the original registrant

## Deployment Instructions

### Method 1: Using Firebase Console (Recommended for beginners)

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Copy the contents of `firestore_security_rules.rules`
5. Paste into the rules editor
6. Click **Publish**

### Method 2: Using Firebase CLI (Recommended for developers)

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```

4. Replace the contents of `firestore.rules` with the contents of `firestore_security_rules.rules`

5. Deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Testing the Rules

### Using Firebase Console
1. Go to **Firestore Database** → **Rules**
2. Click on the **Rules playground** tab
3. Test different scenarios with various user authentication states

### Using Firebase Emulator (Recommended for development)
1. Install the Firebase emulator:
   ```bash
   firebase init emulators
   ```

2. Start the emulator:
   ```bash
   firebase emulators:start
   ```

3. Run your app against the emulator to test the rules

## Important Security Considerations

### Data Validation
The rules include validation for:
- Required fields (timestamps, user IDs, etc.)
- Proper role assignments
- Status transitions
- Ownership verification

### Performance Optimization
- Rules use `exists()` and `get()` sparingly to minimize read operations
- Indexed fields are used for efficient queries
- Complex validations are kept minimal

### Common Pitfalls to Avoid
1. **Don't expose sensitive data**: Ensure private team information isn't accessible
2. **Validate all inputs**: Check data types and required fields
3. **Test thoroughly**: Use the emulator to test edge cases
4. **Monitor usage**: Keep an eye on rule evaluation costs

## Troubleshooting

### Common Errors

**Permission Denied**
- Check if the user is authenticated
- Verify the user has the required role (owner, captain, etc.)
- Ensure the document exists and is accessible

**Invalid Argument**
- Check data types in your client code
- Ensure required fields are present
- Verify timestamp formats

**Resource Not Found**
- Ensure referenced documents exist
- Check document IDs are correct
- Verify collection names match exactly

### Debugging Tips
1. Use the Firebase Console Rules playground
2. Check the Firebase logs for detailed error messages
3. Test with the Firebase emulator for faster iteration
4. Use `console.log()` equivalent in rules for debugging (resource.data)

## Maintenance

### Regular Tasks
1. **Review access patterns**: Monitor who's accessing what data
2. **Update rules**: As features evolve, update security rules accordingly
3. **Performance monitoring**: Watch for expensive rule evaluations
4. **Security audits**: Regularly review rules for potential vulnerabilities

### Version Control
- Keep security rules in version control
- Document changes with clear commit messages
- Test rules before deploying to production
- Consider using staging environments for rule testing

## Support

If you encounter issues with the security rules:
1. Check the Firebase documentation
2. Review the Firebase console logs
3. Test with the emulator
4. Consider reaching out to the development team for assistance
