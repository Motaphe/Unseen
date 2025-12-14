# Unseen

A horror-themed AR scavenger hunt mobile application where players scan QR codes to uncover a dark narrative. Built with Flutter and Firebase.

**Tagline:** "You will wish you hadn't seen"

## Overview

Unseen is an Android mobile app that combines QR code scanning, camera integration, and horror storytelling to create an immersive scavenger hunt experience. Players scan QR codes placed around physical locations to reveal creepy narrative fragments and capture photos with horror-themed AR stickers.

## Links

- **Presentation**: [Unseen Horror AR Scavenger Hunt](https://gamma.app/docs/Unseen-Horror-AR-Scavenger-Hunt-4ih6k7mvvackjtl)
- **Video**: [YouTube Demo](https://youtu.be/MDGvMu4c9G4)

## Architecture

For detailed architecture documentation including system diagrams, data models, service layer design, state management patterns, and technical workflows, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Features

- **QR Code Scavenger Hunt**: Linear progression through story-driven clues
- **Horror Narrative**: Atmospheric storytelling with glitch effects and dark themes
- **Photo Mode**: Capture photos with horror-themed AR sticker overlays
- **Hunt Builder**: Admin tools for creating custom hunts and generating QR codes
- **Firebase Integration**: Cloud-based authentication, data storage, and user progress tracking
- **Offline Mode**: Fallback data service for playing without network connectivity
- **Audio & Haptics**: Immersive horror sound effects and vibration feedback
- **User Profiles**: Track hunt history, completion stats, and photo gallery

## Tech Stack

- **Framework**: Flutter 3.x (Dart)
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Navigation**: GoRouter
- **QR Scanning**: mobile_scanner
- **QR Generation**: qr_flutter
- **Camera**: camera package
- **Audio**: audioplayers
- **Other**: photo_manager, vibration, geolocator

## Prerequisites

- Flutter SDK 3.10.3 or higher
- Android SDK 36+
- Java 17
- Firebase account and project setup
- Android device/emulator for testing

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Motaphe/Unseen.git
   cd unseen
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Email/Password authentication
   - Create a Firestore database
   - Download `google-services.json` and place in `android/app/`
   - Run Firebase CLI configuration:
     ```bash
     flutterfire configure --project=unseen-ar
     ```

4. **Seed initial data**
   ```bash
   flutter run lib/scripts/seed_firestore.dart
   ```

## Building & Running

### Development
```bash
flutter run
```

### Build APK
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

### Clean build
```bash
flutter clean && flutter pub get && flutter run
```

## Project Structure

```
lib/
├── main.dart                   # Application entry point
├── app.dart                    # App configuration and theming
├── config/                     # Theme and routing configuration
├── models/                     # Data models (Hunt, Clue, UserProgress)
├── services/                   # Business logic (Auth, Firestore, QR, Audio)
├── providers/                  # State management
├── screens/                    # UI screens
│   ├── auth/                   # Login and registration
│   ├── home/                   # Main menu and hunt selection
│   ├── hunt/                   # Active gameplay screens
│   ├── profile/                # User profile and settings
│   └── admin/                  # Hunt builder and QR generation
├── widgets/                    # Reusable UI components
└── utils/                      # Constants and helpers
```

## Permissions

The app requires the following Android permissions:
- **CAMERA**: QR scanning and photo capture
- **INTERNET**: Firebase connectivity
- **ACCESS_FINE_LOCATION**: Future location-based features
- **READ/WRITE_EXTERNAL_STORAGE**: Photo gallery access
- **VIBRATE**: Haptic feedback

All permissions are pre-configured in `android/app/src/main/AndroidManifest.xml`.

## Known Issues

- **AR Plugin Disabled**: The original AR plugin (`ar_flutter_plugin`) is incompatible with Android Gradle Plugin 8+. The app uses QR-based gameplay instead.
- **SDK Requirements**: Requires Android SDK 36+ due to plugin dependencies
- **Pub Cache Patches**: The `image_gallery_saver` plugin may require manual namespace addition after `flutter pub cache repair`

## Troubleshooting

### Build Errors

**Java compatibility errors**:
```bash
./fix_java_compatibility.sh
```

**Namespace errors**:
Add `namespace = "com.example.imagegallerysaver"` to the `android { }` block in:
`~/.pub-cache/hosted/pub.dev/image_gallery_saver-2.0.3/android/build.gradle`

**Gradle cache issues**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```