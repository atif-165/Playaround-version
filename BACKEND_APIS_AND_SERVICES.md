# Backend APIs and External Services Documentation

This document provides a comprehensive list of all backend APIs and external services used in the PlayAround project.

---

## 🔥 Firebase Services (Backend APIs)

### 1. **Firebase Firestore**
- **Purpose**: Primary NoSQL database for storing all application data
- **Usage**: 
  - User profiles and authentication data
  - Teams, tournaments, venues, coaches
  - Chat messages and rooms
  - Bookings and listings
  - Matchmaking data
  - Community posts
  - Shop products and orders
  - Skill tracking logs
- **Collections Used**:
  - `users` - User profiles and authentication
  - `teams` - Team information
  - `tournaments` - Tournament data
  - `venues` - Venue listings
  - `coaches` - Coach profiles
  - `chat_rooms` - Chat room data
  - `chat_messages` - Individual chat messages
  - `bookings` - Booking records
  - `listings` - Service listings
  - `public_profiles` - Public user profiles
  - `match_decisions` - Matchmaking swipe decisions
  - `community_posts` - Community feed posts
  - `shop_locations` - Shop location data
  - `session_logs` - Skill tracking session logs
  - `goals` - Skill tracking goals
- **Location**: `lib/services/`, `lib/data/repositories/`, `lib/modules/*/services/`

### 2. **Firebase Authentication**
- **Purpose**: User authentication and authorization
- **Features**:
  - Email/password authentication
  - Google Sign-In integration
  - User session management
  - Token management
- **Endpoints Used**:
  - `https://playaround-6556e.firebaseapp.com/__/auth/action` - Email verification links
- **Location**: `lib/logic/cubit/auth_cubit.dart`, `lib/data/services/firebase_auth_service.dart`

### 3. **Firebase Storage**
- **Purpose**: File storage for images, videos, and documents
- **Usage**:
  - Profile pictures
  - Team/venue/coach images
  - Chat media files
  - Tournament assets
  - Shop product images
- **Location**: `lib/modules/chat/services/chat_service.dart`, various upload services

### 4. **Firebase Cloud Messaging (FCM)**
- **Purpose**: Push notifications for mobile devices
- **API Endpoint**: `https://fcm.googleapis.com/fcm/send`
- **Usage**:
  - Chat message notifications
  - Connection request notifications
  - Booking confirmations
  - Tournament updates
  - General app notifications
- **Configuration**: Requires FCM Server Key (set via `--dart-define=FCM_SERVER_KEY=YOUR_KEY`)
- **Location**: `lib/modules/chat/services/chat_notification_service.dart`

---

## 🖼️ Media & Image Services

### 6. **Cloudinary API**
- **Purpose**: Image upload, storage, and transformation
- **API Endpoint**: Cloudinary REST API (via `cloudinary` package)
- **Features**:
  - Image upload with presets
  - Image transformation (resize, crop, quality optimization)
  - Profile image management
  - Shop location images
  - Automatic image optimization
- **Configuration**:
  - Cloud Name: `dlt281zr0`
  - API Key: Configured in `lib/config/cloudinary_config.dart`
  - Upload Preset: `profile_images_preset`
- **Location**: `lib/services/cloudinary_service.dart`, `lib/config/cloudinary_config.dart`

---

## 🗺️ Location & Maps Services

### 7. **Google Maps API**
- **Purpose**: Maps display, location search, and directions
- **Features**:
  - Interactive maps for venues and shop locations
  - Location search and geocoding
  - Directions and navigation
  - Place details
- **Usage**:
  - Venue location display
  - Shop location mapping
  - Tournament venue directions
  - Google Maps link generation
- **URL Patterns Used**:
  - `https://www.google.com/maps/search/?api=1&query=...` - Location search
  - `https://www.google.com/maps/dir/?api=1&destination=...` - Directions
- **Location**: `lib/modules/venue/`, `lib/modules/shop/screens/shop_map_screen.dart`, `lib/screens/venue/`

### 8. **Geolocator Service**
- **Purpose**: Device location services
- **Features**:
  - Current location detection
  - Location permissions handling
  - Distance calculations
  - Location accuracy settings
- **Location**: `lib/services/location_service.dart`

---

## 🔐 Authentication Services

### 9. **Google Sign-In API**
- **Purpose**: OAuth authentication via Google accounts
- **Features**:
  - Google account authentication
  - User profile data retrieval
  - Token management
- **Integration**: Works with Firebase Auth
- **Location**: `lib/logic/cubit/auth_cubit.dart`, `lib/data/services/firebase_auth_service.dart`

---

## 📱 Other External Services

### 10. **Zego Cloud (Video Calling)**
- **Purpose**: Video and voice calling functionality
- **Package**: `zego_uikit_prebuilt_call: ^4.21.1`
- **Usage**: In-app video/voice calls for chat and team communication
- **Location**: Referenced in `pubspec.yaml`

### 11. **Metadata Fetch**
- **Purpose**: URL metadata extraction
- **Package**: `metadata_fetch: ^0.4.2`
- **Usage**: Extracting metadata from shared links (e.g., social media links, venue links)

---

## 📊 Summary Table

| Service | Type | Primary Use Case | API Endpoint/Service |
|---------|------|------------------|---------------------|
| Firebase Firestore | Database | Data storage and retrieval | Firestore REST API / SDK |
| Firebase Auth | Authentication | User login/signup | Firebase Auth API |
| Firebase Storage | File Storage | Media file storage | Firebase Storage API |
| Firebase Cloud Messaging | Push Notifications | Mobile push notifications | `https://fcm.googleapis.com/fcm/send` |
| Cloudinary | Image Hosting | Image upload and transformation | Cloudinary REST API |
| Google Maps | Maps & Location | Maps display and directions | Google Maps API |
| Geolocator | Location Services | Device location detection | Platform location services |
| Google Sign-In | OAuth | Social authentication | Google OAuth API |
| Zego Cloud | Video Calling | Video/voice calls | Zego Cloud API |

---

## 🔧 Configuration Requirements

### Environment Variables Needed:
1. **FCM_SERVER_KEY** - Firebase Cloud Messaging server key
5. **FIREBASE_WEB_API_KEY** - Firebase web API key (for web builds)
6. **FIREBASE_PROJECT_ID** - Firebase project ID
7. **FIREBASE_MESSAGING_SENDER_ID** - Firebase messaging sender ID

### Firebase Configuration:
- **Project ID**: `playaround-6556e`
- **Storage Bucket**: `playaround-6556e.firebasestorage.app`
- **Region**: `asia-south1` (for Firestore)

### Cloudinary Configuration:
- **Cloud Name**: `dlt281zr0`
- **Upload Preset**: `profile_images_preset`

---

## 📝 Notes

1. **Firebase Services**: All Firebase services are accessed through the Firebase SDK, not direct REST API calls (except FCM which uses HTTP POST).

3. **Image Upload**: Images are uploaded to Cloudinary using signed configuration with upload presets for security.

4. **Location Services**: The app uses both Google Maps API (for maps display) and device location services (via Geolocator) for location-based features.

5. **Real-time Features**: Firestore provides real-time data synchronization through streams, enabling live updates for chat, notifications, and other features.

6. **Offline Support**: Firestore has offline persistence enabled, allowing the app to work offline and sync when connectivity is restored.

---

## 🔗 Related Files

- **Firebase Configuration**: `lib/firebase_options.dart`
- **Cloudinary Configuration**: `lib/config/cloudinary_config.dart`
- **Payment Service**: `lib/services/payment_service.dart`
- **Chat Notification Service**: `lib/modules/chat/services/chat_notification_service.dart`
- **Location Service**: `lib/services/location_service.dart`
- **Dependencies**: `pubspec.yaml`

---

*Last Updated: Based on codebase analysis*
*Project: PlayAround - Sports Social App*

