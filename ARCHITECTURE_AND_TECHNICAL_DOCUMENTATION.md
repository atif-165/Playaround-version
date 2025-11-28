# PlayAround App - Architecture & Technical Documentation

## **Application Architecture Overview**

### **1. Platform & Framework**
- **Framework**: Flutter (Dart SDK >=3.4.0)
- **Platform**: Cross-platform (Android, iOS, Web, Linux, macOS, Windows)
- **App Type**: Sports social networking app (PlayAround)
- **Version**: 1.0.0+1

---

## **2. Architecture Pattern**

### **Layered Architecture with Feature Modules**

The app uses a layered architecture with feature-based modules:

```
┌─────────────────────────────────────┐
│     Presentation Layer (UI)         │
│  - Screens                          │
│  - Widgets                          │
│  - Presentation Components          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│     State Management Layer          │
│  - BLoC/Cubit (Primary)             │
│  - Riverpod (Limited - Community)   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│     Business Logic Layer            │
│  - Services                         │
│  - Repositories                     │
│  - Data Sources                     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│     Data Layer                      │
│  - Firebase Firestore               │
│  - Firebase Storage                 │
│  - Local Cache (Hive)               │
│  - Sync Manager                     │
└─────────────────────────────────────┘
```

---

## **3. State Management Approach**

### **Primary: BLoC/Cubit Pattern**
- **Package**: `flutter_bloc: ^9.1.1`
- **Usage**: Main state management across the app
- **Cubits Used**:
  - `AuthCubit` - Authentication state
  - `OnboardingCubit` - User onboarding flow
  - `DashboardCubit` - Dashboard state
  - `TeamCubit` - Team management
  - `TournamentCubit` - Tournament management

### **Secondary: Riverpod**
- **Package**: `flutter_riverpod: ^2.5.1`, `hooks_riverpod: ^2.5.1`
- **Usage**: Limited to specific features (e.g., Community Feed)
- **Pattern**: Used alongside BLoC for specific modules

### **State Management Flow**:
```
UI Widget → BlocBuilder/BlocListener → Cubit → Service → Repository → Data Source
```

---

## **4. Folder Structure & Organization**

### **Feature-Based Module Structure**:
```
lib/
├── modules/              # Feature modules (self-contained)
│   ├── team/            # Team feature
│   │   ├── cubit/       # State management
│   │   ├── services/    # Business logic
│   │   ├── models/      # Domain models
│   │   ├── screens/     # UI screens
│   │   └── widgets/     # Feature widgets
│   ├── tournament/      # Tournament feature
│   ├── chat/            # Chat feature
│   ├── venue/           # Venue feature
│   ├── coach/           # Coach feature
│   ├── booking/         # Booking feature
│   ├── skill_tracking/  # Skill tracking
│   └── shop/            # Shop feature
│
├── screens/             # Global screens
├── services/            # Shared services
├── repositories/        # Data repositories
├── models/              # Shared models
├── logic/               # Global state (Cubits)
├── data/                # Data layer
│   ├── datasources/    # Data sources
│   ├── repositories/   # Repository implementations
│   └── local/          # Local storage
├── core/               # Core utilities
│   ├── widgets/        # Reusable widgets
│   ├── utils/          # Utilities
│   └── constants/      # Constants
├── routing/            # Navigation
├── theming/            # App theming
└── helpers/            # Helper functions
```

---

## **5. Data Layer Architecture**

### **Repository Pattern**
- **Purpose**: Abstracts data sources and provides a clean API
- **Examples**:
  - `UserRepository` - User profile management
  - `BookingRepository` - Booking data management
  - `DiscoveryRepository` - Discovery/matchmaking data
  - `DashboardRepository` - Dashboard data

### **Data Sources**:
1. **Firestore Data Sources**:
   - `FirestoreBookingDataSource`
   - `FirestoreMatchmakingDataSource`
2. **Mock Data Sources** (for testing):
   - `MockDataSource`

### **Caching Strategy**:
- **Service**: `FirestoreCacheService` - Local caching layer
- **Storage**: Hive for local persistence
- **Cache Duration**: Configurable (typically 5-20 minutes)
- **Offline Support**: Firestore persistence enabled

### **Data Flow**:
```
Service → Repository → Data Source → Firebase Firestore
         ↓
    Cache Service (Hive)
```

---

## **6. Service Layer Pattern**

### **Singleton Services**
Most services use the Singleton pattern:
```dart
class VenueService {
  static final VenueService _instance = VenueService._internal();
  factory VenueService() => _instance;
  VenueService._internal();
}
```

### **Service Examples**:
- `VenueService` - Venue management
- `ChatService` - Chat functionality
- `TeamService` - Team operations
- `TournamentService` - Tournament operations
- `CoachService` - Coach management
- `NotificationService` - Push notifications
- `PaymentService` - Payment processing
- `LocationService` - Location services
- `CloudinaryService` - Image upload/management
- `MatchmakingService` - Player matchmaking
- `RatingService` - Rating system
- `SessionService` - Session management
- `UserActivityService` - User activity tracking

---

## **7. Backend & External Services**

### **Firebase Services** (Primary Backend):
1. **Firestore** - NoSQL database
   - Collections: `users`, `teams`, `tournaments`, `venues`, `coaches`, `chat_rooms`, `chat_messages`, `bookings`, `listings`, `public_profiles`, `match_decisions`, `community_posts`, `shop_locations`, `session_logs`, `goals`
   - Real-time synchronization
   - Offline persistence enabled
   
2. **Firebase Auth** - Authentication
   - Email/password authentication
   - Google Sign-In integration
   - User session management
   - Token management
   
3. **Firebase Storage** - File storage
   - Profile pictures
   - Team/venue/coach images
   - Chat media files
   - Tournament assets
   - Shop product images
   
4. **Firebase Cloud Messaging (FCM)** - Push notifications
   - Chat message notifications
   - Connection request notifications
   - Booking confirmations
   - Tournament updates
   - General app notifications

### **Third-Party Services**:
- **Cloudinary** - Image hosting and transformation
  - Cloud Name: `dlt281zr0`
  - Upload Preset: `profile_images_preset`
  - Image transformation and optimization
  
- **Google Maps API** - Maps and location services
  - Interactive maps for venues and shop locations
  - Location search and geocoding
  - Directions and navigation
  
- **Zego Cloud** - Video/voice calling
  - Package: `zego_uikit_prebuilt_call: ^4.21.1`
  - In-app video/voice calls for chat and team communication
  
- **Geolocator** - Device location services
  - Current location detection
  - Location permissions handling
  - Distance calculations

---

## **8. Navigation & Routing**

### **Routing Approach**:
- **Pattern**: Named routes with `MaterialPageRoute`
- **Router**: Custom `AppRouter` class with `generateRoute` method
- **Navigation**: Traditional Flutter navigation (not GoRouter despite dependency)

### **Route Management**:
- Centralized route definitions in `AppRoutePath`
- Route generation in `AppRouter.generateRoute()`
- Argument passing via `RouteSettings.arguments`

### **Key Routes**:
- `/splash` - Splash screen
- `/auth/login` - Login screen
- `/auth/signup` - Sign up screen
- `/dashboard` - Dashboard
- `/venue-discovery` - Venue discovery
- `/chat-list` - Chat list
- `/team-list` - Team list
- `/tournament-list` - Tournament list
- `/community-home` - Community feed
- `/shop` - Shop screen
- `/notifcation` - Notification

---

## **9. UI/UX Architecture**

### **Responsive Design**:
- **Package**: `flutter_screenutil: ^5.9.1`
- **Design Size**: 360x690 (mobile-first)
- **Features**: Screen size adaptation, text scaling
- **Split Screen Mode**: Enabled for tablet support

### **Theming**:
- **Location**: `lib/theming/`
- **Support**: Light/Dark themes
- **Theme Mode**: System-based (`ThemeMode.system`)
- **Files**:
  - `app_theme.dart` - Main theme configuration
  - `colors.dart` - Color definitions
  - `typography.dart` - Text styles
  - `styles.dart` - Common styles

### **UI Components**:
- **Reusable Widgets**: `lib/core/widgets/` (29 widget files)
- **Feature Widgets**: Within each module
- **Custom Widgets**: Built for specific features

### **Image Handling**:
- **Package**: `cached_network_image: ^3.4.1` - Cached network images
- **SVG Support**: `flutter_svg: ^2.0.10+1`
- **Image Picker**: `image_picker: ^1.1.2`
- **Image Compression**: `flutter_image_compress: ^2.1.0`

---

## **10. Code Organization Patterns**

### **Separation of Concerns**:
1. **Models**: Domain models with Firestore serialization
   - Located in `lib/models/` and `lib/modules/*/models/`
   - Support for JSON serialization
   - Freezed for immutable classes
   
2. **Services**: Business logic and API interactions
   - Located in `lib/services/` and `lib/modules/*/services/`
   - Singleton pattern for global services
   - Feature-specific services in modules
   
3. **Repositories**: Data access abstraction
   - Located in `lib/repositories/` and `lib/data/repositories/`
   - Abstract data sources
   - Support multiple data sources (Firestore, Mock)
   
4. **Cubits**: State management
   - Located in `lib/logic/cubit/` and `lib/modules/*/cubit/`
   - Handle business logic state
   - Emit states for UI updates
   
5. **Screens**: UI presentation
   - Located in `lib/screens/` and `lib/modules/*/screens/`
   - Feature-specific screens in modules
   - Global screens in root screens folder
   
6. **Widgets**: Reusable UI components
   - Located in `lib/core/widgets/` and `lib/modules/*/widgets/`
   - Reusable across features
   - Feature-specific widgets in modules

### **Dependency Injection**:
- **Pattern**: Constructor injection
- **Example**: Services injected into Cubits, Repositories injected into Services
- **Testing**: Supports dependency override for testing
- **Example**:
  ```dart
  UserRepository({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinaryService,
    FirestoreCacheService? cacheService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cloudinaryService = cloudinaryService ?? CloudinaryService(),
       _cacheService = cacheService ?? FirestoreCacheService.instance;
  ```

### **Error Handling**:
- Try-catch blocks in services/repositories
- User-friendly error messages
- Firebase exception mapping
- Debug logging in development mode
- Example error handling:
  ```dart
  try {
    // Operation
  } on FirebaseException catch (e) {
    throw _handleFirebaseException(e);
  } catch (e) {
    throw Exception('Failed to perform operation');
  }
  ```

---

## **11. Local Storage & Offline Support**

### **Local Storage**:
- **Hive**: Local NoSQL database (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`)
  - Fast key-value storage
  - Type-safe boxes
  - Used for caching and offline data
  
- **Shared Preferences**: Simple key-value storage
  - Package: `shared_preferences` (via Flutter SDK)
  - User preferences and settings
  
- **Secure Storage**: `flutter_secure_storage: ^9.2.2`
  - Sensitive data storage
  - Encrypted storage for tokens and credentials

### **Offline Support**:
- **Firestore Persistence**: Enabled (`persistenceEnabled: true`)
  - Automatic offline data caching
  - Sync when connection restored
  
- **Sync Manager**: `SyncManager` for data synchronization
  - Location: `lib/data/local/sync_manager.dart`
  - Manages offline data sync
  - Handles conflict resolution
  
- **Cache Service**: `FirestoreCacheService` for offline data access
  - Location: `lib/services/firestore_cache_service.dart`
  - Document-level caching
  - Collection-level caching
  - Configurable cache expiration

---

## **12. Testing Approach**

### **Testing Packages**:
- `flutter_test` - Unit/widget testing (Flutter SDK)
- `bloc_test: 10.0.0` - BLoC testing
- `mocktail: ^1.0.4` - Mocking framework
- `firebase_auth_mocks: ^0.14.1` - Firebase mocking
- `fake_cloud_firestore: ^3.1.0` - Firestore mocking

### **Test Structure**:
```
test/
├── auth/                    # Authentication tests
├── booking_flow_test.dart    # Booking flow integration test
├── booking_status_test.dart # Booking status test
├── chat_integration_test.dart # Chat integration test
├── community_service_test.dart # Community service test
├── core/                    # Core functionality tests
├── dashboard/               # Dashboard tests
├── helpers/                 # Test helpers
├── matchmaking_test.dart    # Matchmaking test
├── modules/                 # Module-specific tests
├── navigation_test.dart     # Navigation test
├── notifications_test.dart  # Notifications test
├── payment_flow_test.dart   # Payment flow test
├── profile_data_service_test.dart # Profile service test
├── schedule_test.dart       # Schedule test
├── screens/                 # Screen tests
├── skill_repository_test.dart # Skill repository test
└── tournament_system_test.dart # Tournament system test
```

### **Testing Patterns**:
- Unit tests for services and repositories
- Widget tests for UI components
- Integration tests for user flows
- Mock data sources for isolated testing

---

## **13. Code Generation**

### **Packages Used**:
- `freezed: ^2.4.7` - Immutable classes and unions
  - Generates: `.freezed.dart` files
  - Used for state classes and models
  - Provides union types and sealed classes
  
- `json_serializable: ^6.7.1` - JSON serialization
  - Generates: `.g.dart` files
  - Automatic JSON encoding/decoding
  - Used for Firestore serialization
  
- `build_runner: ^2.4.9` - Code generation tool
  - Command: `flutter pub run build_runner build`
  - Watch mode: `flutter pub run build_runner watch`

### **Generated Files**:
- `.freezed.dart` - Freezed generated code (immutable classes, unions)
- `.g.dart` - JSON serialization code (toJson/fromJson methods)

### **Usage Example**:
```dart
@freezed
class TeamState with _$TeamState {
  const factory TeamState.initial() = _Initial;
  const factory TeamState.loading() = _Loading;
  const factory TeamState.loaded(List<TeamModel> teams) = _Loaded;
  const factory TeamState.error(String message) = _Error;
}
```

---

## **14. Key Technical Patterns**

### **1. Stream-Based Data Flow**:
- Real-time updates using Firestore streams
- Stream subscriptions in Cubits
- Stream debouncing for performance
- Example:
  ```dart
  _teamsSubscription = _teamService
      .getTeamsStream(sportType: sportType)
      .listen(
        (teams) => emit(TeamState.loaded(teams)),
        onError: (error) => emit(TeamState.error(error.toString())),
      );
  ```

### **2. Singleton Pattern**:
- Services use singleton for global access
- Cache services as singletons
- Example:
  ```dart
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  ```

### **3. Factory Pattern**:
- Repository factory methods
- Service factory constructors
- Model factory constructors (fromFirestore, fromMap)

### **4. Repository Pattern**:
- Abstraction between data sources and business logic
- Multiple data source support (Firestore, Mock)
- Clean API for data operations
- Example:
  ```dart
  class BookingRepository {
    final FirestoreBookingDataSource _bookingDataSource;
    final MockDataSource _mockDataSource;
    
    Future<List<BookingModel>> getBookings(String userId) {
      // Repository logic
    }
  }
  ```

### **5. Provider Pattern**:
- BLoC providers at app level
- Riverpod providers for specific features
- Example:
  ```dart
  MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => AuthCubit()),
      BlocProvider(create: (context) => DashboardCubit()),
    ],
    child: MyApp(),
  )
  ```

### **6. Observer Pattern**:
- Stream listeners for real-time updates
- BLoC observers for state changes
- Firestore snapshot listeners

---

## **15. Development Practices**

### **Code Quality**:
- `flutter_lints: ^4.0.0` - Linting rules
- `analysis_options.yaml` - Static analysis configuration
- Code formatting standards
- Naming conventions

### **Internationalization**:
- `intl: ^0.19.0` - Internationalization
- Custom localization system (`lib/core/i18n/`)
- JSON-based translations (`en_us.json`)
- `AppLocalizations` class for translations

### **Logging & Debugging**:
- Debug print statements with emoji prefixes for categorization
  - 🔍 Search/Query operations
  - ✅ Success operations
  - ❌ Error operations
  - 📦 Cache operations
  - 🚀 Upload operations
  - 💥 Exception handling
- Conditional logging based on `kDebugMode`
- Mock push generator for development
- Example:
  ```dart
  if (kDebugMode) {
    debugPrint('🔍 UserRepository: Getting profile for UID: $uid');
  }
  ```

### **Error Handling Strategy**:
- Firebase exception mapping to user-friendly messages
- Graceful error handling in UI
- Error states in Cubits
- Retry mechanisms for network operations

---

## **16. Key Dependencies**

### **State Management**:
- `flutter_bloc: ^9.1.1` - BLoC pattern
- `flutter_riverpod: ^2.5.1` - Riverpod state management
- `hooks_riverpod: ^2.5.1` - Riverpod hooks
- `flutter_hooks: ^0.20.5` - Flutter hooks

### **Firebase**:
- `firebase_core: ^3.6.0` - Firebase core
- `firebase_auth: ^5.3.1` - Authentication
- `cloud_firestore: ^5.4.4` - Firestore database
- `firebase_storage: ^12.3.4` - Storage
- `firebase_messaging: ^15.1.3` - Cloud Messaging

### **UI/UX**:
- `flutter_screenutil: ^5.9.1` - Responsive design
- `cached_network_image: ^3.4.1` - Cached images
- `shimmer: ^3.0.0` - Loading shimmer effect
- `fl_chart: ^1.0.0` - Charts and graphs
- `table_calendar: ^3.1.2` - Calendar widget
- `swipable_stack: ^2.0.0` - Swipable cards

### **Media**:
- `video_player: ^2.9.1` - Video playback
- `video_compress: ^3.1.3` - Video compression
- `video_thumbnail: ^0.5.3` - Video thumbnails
- `photo_view: ^0.15.0` - Image viewer
- `just_audio` - Audio playback

### **Location & Maps**:
- `geolocator: ^14.0.2` - Location services
- `google_maps_flutter: ^2.5.3` - Google Maps
- `geoflutterfire_plus: ^0.0.32` - Geo queries

### **Communication**:
- `zego_uikit_prebuilt_call: ^4.21.1` - Video calling
- `emoji_picker_flutter: ^3.0.0` - Emoji picker

### **Storage & Cache**:
- `hive: ^2.2.3` - Local database
- `hive_flutter: ^1.1.0` - Hive Flutter integration
- `flutter_secure_storage: ^9.2.2` - Secure storage
- `path_provider: ^2.1.3` - File paths

### **Utilities**:
- `uuid: ^4.4.0` - UUID generation
- `intl: ^0.19.0` - Internationalization
- `timeago: ^3.7.0` - Relative time
- `crypto: ^3.0.3` - Cryptography
- `http: ^1.1.0` - HTTP client

### **Code Generation**:
- `freezed: ^2.4.7` - Immutable classes
- `json_serializable: ^6.7.1` - JSON serialization
- `build_runner: ^2.4.9` - Code generation

---

## **17. Module-Specific Architecture**

### **Team Module** (`lib/modules/team/`):
- **Cubit**: `TeamCubit` - Team state management
- **Service**: `TeamService` - Team operations
- **Models**: `TeamModel`, `TeamJoinRequest`, `TeamMatchModel`
- **Screens**: Team list, team detail, team management, team admin
- **Features**: Team creation, member management, team matches, team schedule

### **Tournament Module** (`lib/modules/tournament/`):
- **Cubit**: `TournamentCubit` - Tournament state management
- **Service**: `TournamentService` - Tournament operations
- **Models**: `TournamentModel`
- **Screens**: Tournament list, tournament detail, create tournament
- **Features**: Tournament creation, bracket management, match scheduling

### **Chat Module** (`lib/modules/chat/`):
- **Service**: `ChatService` - Chat functionality (Singleton)
- **Models**: `ChatMessage`, `ChatRoom`, `Connection`
- **Screens**: Chat list, chat screen, user search
- **Features**: Real-time messaging, media sharing, video calls

### **Venue Module** (`lib/modules/venue/`):
- **Service**: `VenueService` - Venue management (Singleton)
- **Models**: `Venue`, `VenueBooking`, `VenueReview`
- **Screens**: Venue discovery, venue profile, venue booking
- **Features**: Venue search, booking management, reviews

### **Skill Tracking Module** (`lib/modules/skill_tracking/`):
- **Services**: 
  - `SkillTrackingService` - Skill tracking
  - `AutomatedSkillService` - Automated skill updates
  - `SkillDecayService` - Skill decay management
  - `SkillIntegrationService` - Integration service
- **Models**: `SessionLog`, `Goal`, `SkillType`
- **Screens**: Skill dashboard, analytics dashboard
- **Features**: Skill logging, goal tracking, analytics

### **Community Module** (`lib/modules/community/`):
- **State Management**: Riverpod (HookConsumerWidget)
- **Models**: `CommunityPost`
- **Screens**: Community feed, post detail, create post
- **Features**: Social feed, post creation, moderation

### **Shop Module** (`lib/modules/shop/`):
- **Services**: `ShopLocationService`, `LocationReviewService`
- **Models**: `ShopLocation`
- **Screens**: Shop screen, shop map, location detail
- **Features**: Shop locations, product management, orders

---

## **18. Data Models**

### **User Models**:
- `UserProfile` - Base user profile
- `PlayerProfile` - Player-specific profile
- `CoachProfile` - Coach-specific profile

### **Booking Models**:
- `BookingModel` - Booking data model
- `VenueBooking` - Venue booking model
- `ListingModel` - Service listing model

### **Matchmaking Models**:
- `MatchProfile` - Match profile
- `MatchDecision` - Swipe decision
- `PlayerModel` - Player model for matchmaking

### **Team Models**:
- `TeamModel` - Team data model
- `TeamJoinRequest` - Join request model
- `TeamMatchModel` - Team match model
- `TeamSchedule` - Team schedule model

### **Tournament Models**:
- `TournamentModel` - Tournament data model

### **Venue Models**:
- `Venue` - Venue model
- `VenueReview` - Review model
- `VenueBooking` - Booking model

---

## **19. Security & Authentication**

### **Authentication Flow**:
1. User signs in with email/password or Google
2. Firebase Auth handles authentication
3. `AuthCubit` manages auth state
4. User profile checked via `UserRepository`
5. Onboarding flow if profile incomplete
6. Navigation to main app if profile complete

### **Security Features**:
- Firebase Security Rules for Firestore
- Secure storage for sensitive data
- Token-based authentication
- Email verification
- Password reset functionality

### **Firestore Security Rules**:
- Location: `firestore_security_rules.rules`
- Collection-level access control
- User-based data access
- Role-based permissions

---

## **20. Performance Optimizations**

### **Caching Strategy**:
- Document-level caching (20 minutes for users)
- Collection-level caching (5 minutes for bookings)
- In-memory caching in services
- Hive-based persistent cache

### **Image Optimization**:
- Cloudinary image transformation
- Cached network images
- Image compression before upload
- Lazy loading for images

### **Stream Debouncing**:
- Debounced stream subscriptions
- Prevents excessive updates
- Location: `lib/core/utils/stream_debounce.dart`

### **Lazy Loading**:
- Pagination for lists
- Infinite scroll implementation
- Limit-based queries

---

## **21. Build & Deployment**

### **Build Configuration**:
- Android: `android/app/build.gradle`
- iOS: `ios/Runner.xcodeproj`
- Web: `web/` directory
- Desktop: Platform-specific configurations

### **Environment Variables**:
- `FCM_SERVER_KEY` - Firebase Cloud Messaging key
- `FIREBASE_WEB_API_KEY` - Firebase web API key
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_MESSAGING_SENDER_ID` - Messaging sender ID

### **Firebase Configuration**:
- Project ID: `playaround-6556e`
- Storage Bucket: `playaround-6556e.firebasestorage.app`
- Region: `asia-south1` (for Firestore)

---

## **22. Summary**

This app uses a **layered, feature-module architecture** with:

- **State Management**: BLoC/Cubit (primary), Riverpod (limited)
- **Data Layer**: Repository pattern with Firestore + local caching
- **Architecture**: Feature-based modules with clear separation of concerns
- **Backend**: Firebase (Firestore, Auth, Storage, FCM)
- **Patterns**: Singleton services, Repository pattern, Stream-based data flow
- **Offline Support**: Firestore persistence + local caching
- **Testing**: Unit/widget tests with mocking support
- **Code Quality**: Linting, code generation, type safety
- **Performance**: Caching, lazy loading, image optimization

The codebase is organized for **scalability, maintainability, and testability** with clear boundaries between layers and well-defined patterns throughout.

---

## **23. Key Files Reference**

### **Entry Point**:
- `lib/main.dart` - Application entry point

### **Routing**:
- `lib/routing/app_router.dart` - Route definitions
- `lib/config/app_routes.dart` - Route paths

### **State Management**:
- `lib/logic/cubit/auth_cubit.dart` - Authentication state
- `lib/logic/cubit/onboarding_cubit.dart` - Onboarding state
- `lib/logic/cubit/dashboard_cubit.dart` - Dashboard state

### **Data Layer**:
- `lib/repositories/user_repository.dart` - User repository
- `lib/data/repositories/booking_repository.dart` - Booking repository
- `lib/services/firestore_cache_service.dart` - Cache service

### **Configuration**:
- `lib/firebase_options.dart` - Firebase configuration
- `lib/config/cloudinary_config.dart` - Cloudinary configuration
- `pubspec.yaml` - Dependencies and app metadata

---

*Last Updated: Based on comprehensive codebase analysis*  
*Project: PlayAround - Sports Social App*  
*Version: 1.0.0+1*

