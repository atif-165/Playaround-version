# PlayAround - Sports Social App

A comprehensive Flutter application for sports enthusiasts to connect, book venues, find coaches, track skills, and participate in tournaments.

## 🏆 Features

### Core Functionality
- **User Authentication**: Secure email/password and Google Sign-In with Firebase
- **Player & Coach Profiles**: Comprehensive profile management with skill tracking
- **Venue Booking**: Real-time venue discovery and booking system
- **Matchmaking**: Intelligent player matching based on location, skill level, and preferences
- **Chat System**: Real-time messaging with emoji support
- **Tournament Management**: Create and participate in tournaments
- **Skill Tracking**: Advanced skill progression monitoring with analytics
- **Rating System**: Peer-to-peer rating and feedback system
- **Shop Module**: Browse and purchase sports equipment with cart functionality

### UI/UX Features
- **Material 3 Design**: Modern, accessible design following Google's latest guidelines
- **Responsive Layout**: Adaptive design for mobile, tablet, and desktop
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Accessibility**: WCAG AA compliant with screen reader support
- **Smooth Animations**: 60fps animations with proper Material motion
- **Intuitive Navigation**: Material 3 NavigationBar with context-aware FABs

### Technical Features
- **Clean Architecture**: Modular, scalable codebase following Clean Architecture principles
- **Real-time Updates**: Firebase Firestore integration for live data synchronization
- **Offline Support**: Connectivity-aware UI with offline capabilities
- **Responsive Design**: Adaptive UI for various screen sizes using ScreenUtil
- **Location Services**: GPS-based venue and player discovery
- **Push Notifications**: Firebase Cloud Messaging integration
- **Image Management**: Cloudinary integration for optimized image handling
- **Type Safety**: Full null safety and strong typing throughout

## 🎨 Material 3 Components

The app features a comprehensive Material 3 design system with reusable components:

### Core Components
- **Buttons**: Filled, Outlined, Text buttons with loading states and variants
- **Cards**: Elevated, Filled, Outlined cards for different content types
- **Input Fields**: Text fields, search fields, dropdowns with validation
- **Dialogs**: Confirmation, loading, success, error, and bottom sheet dialogs
- **Chips & Badges**: Filter chips, status badges, notification indicators

### Specialized Components
- **Product Cards**: E-commerce product display with ratings and actions
- **Profile Cards**: Player/Coach information with avatars and stats
- **Notification Cards**: Rich notifications with actions and timestamps
- **Rating Components**: Interactive star ratings and feedback forms
- **Navigation**: Material 3 NavigationBar with smooth transitions

## 📱 Play Store Ready

The app is configured and ready for Play Store release:

- **Version**: 1.0.0+1 (initial release)
- **Package Name**: `com.playaround.app`
- **Permissions**: Properly configured for sports app functionality
- **App Icons**: Adaptive icon support (icons need to be created)
- **Splash Screen**: Branded launch screen with PlayAround theming
- **Build Configuration**: Release-ready with security optimizations

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.4.0)
- Firebase project with Authentication, Firestore, Storage, and Messaging enabled
- Cloudinary account for image management
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd playaround_auth
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your project configuration

4. Configure Cloudinary:
   - Update `lib/config/cloudinary_config.dart` with your credentials

5. Run the app:
   ```bash
   flutter run
   ```

## 📱 Architecture

The app follows Clean Architecture principles with feature-first organization:

```
lib/
├── core/           # Shared utilities, widgets, and configurations
├── modules/        # Feature modules (chat, booking, tournaments, etc.)
├── models/         # Data models
├── services/       # Business logic services
├── repositories/   # Data access layer
├── screens/        # UI screens
└── theming/        # App theming and styles
```

## 🛠 Tech Stack

- **Framework**: Flutter
- **State Management**: BLoC/Cubit
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Image Management**: Cloudinary
- **Maps & Location**: Geolocator, GeoFlutterFire
- **UI Components**: Material 3 Design System
- **Charts**: FL Chart
- **Animations**: Rive

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support and questions, please open an issue in the repository.

