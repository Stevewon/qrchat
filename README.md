# QR Chat - Flutter Application

Version: 9.13.0

## 📱 Description
QR Chat is a Flutter-based mobile application for real-time chat communication using QR codes. Users can scan QR codes to connect and chat with each other.

## ✨ Features
- QR Code-based user connection
- Real-time messaging
- Profile photos
- Firebase integration
- Push notifications (FCM)
- Cross-platform support (Android, iOS, Web, Desktop)

## 🛠 Tech Stack
- **Framework**: Flutter 3.9.2+
- **Backend**: Firebase
  - Firebase Auth
  - Cloud Firestore
  - Firebase Storage
  - Firebase Messaging (FCM)
- **State Management**: Provider pattern
- **Platform**: Android, iOS, Web, Linux, macOS, Windows

## 📋 Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account and project setup

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Setup
See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed Firebase configuration instructions.

### 3. Run the App
```bash
# Run on connected device
flutter run

# Run on specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

### 4. Build Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📁 Project Structure
```
lib/
├── main.dart              # Application entry point
├── firebase_options.dart  # Firebase configuration
├── models/               # Data models
├── screens/              # UI screens
├── services/             # Business logic & Firebase services
├── utils/                # Utility functions
└── widgets/              # Reusable UI components

assets/
└── sounds/               # Sound files (notifications)

android/                  # Android platform code
ios/                      # iOS platform code
web/                      # Web platform code
```

## 🔧 Configuration
- **pubspec.yaml**: Dependencies and app metadata
- **android/app/build.gradle.kts**: Android build configuration
- **ios/Runner/Info.plist**: iOS configuration
- **Firebase**: See FIREBASE_SETUP.md

## 📱 Supported Platforms
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Linux
- ✅ macOS
- ✅ Windows

## 📦 Key Dependencies
- `firebase_core`: ^3.6.0
- `firebase_auth`: ^5.3.1
- `cloud_firestore`: ^5.4.3
- `firebase_storage`: ^12.3.2
- `firebase_messaging`: ^15.1.3
- `package_info_plus`: ^8.1.2

## 🔐 Security
- Firebase security rules configured
- Authentication required for messaging
- Secure storage for user data

## 📝 Version History
- v9.13.0 - Current version
- v9.18.1 - Latest APK release
- v7.5.0 - Previous stable version

## 🤝 Contributing
1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📄 License
Proprietary - All rights reserved

## 📞 Support
For issues and questions, please open an issue in the repository.

---

**Repository**: https://github.com/Stevewon/qrchat
