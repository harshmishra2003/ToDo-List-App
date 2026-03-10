# Tasky — To-Do List App 📝

A beautiful, production-ready Flutter To-Do List application built with Firebase Authentication, Firebase Realtime Database (REST API), and Provider state management.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20RTDB-orange?logo=firebase)
![Provider](https://img.shields.io/badge/State-Provider-purple)
![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)

---

## ✨ Features

- 🔐 **Firebase Authentication** — Email/Password + Google Sign-In
- ✅ **Task CRUD** — Add, Edit, Delete, Mark Complete with animations
- 🔍 **Filter Tasks** — All / Active / Done filters
- ☁️ **Firebase Realtime DB** — Full REST API via `Dio` (no direct SDK)
- 📴 **Offline Mode** — Automatically falls back to local storage (max 5 tasks)
- 🔄 **Optimistic UI** — Instant feedback before server confirms
- 🎨 **Material 3 Dark Theme** — Glassmorphism, gradients, smooth animations
- 📊 **Task Statistics** — Live count of Total / Active / Completed

---

## 🏗️ Architecture

```
lib/
├── core/           # Theme, constants, router
├── models/         # Task data model
├── services/       # Firebase Auth, Realtime DB REST, Local Storage
├── providers/      # AuthProvider, TaskProvider (state management)
└── screens/        # Splash, Login, Signup, Home + widgets
```

**State Management:** Provider (ChangeNotifier)  
**Database:** Firebase Realtime Database via REST API (Dio HTTP client)  
**Local Fallback:** SharedPreferences (offline mode, max 5 tasks)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Android Studio / VS Code
- Firebase project ([console.firebase.google.com](https://console.firebase.google.com))

### Firebase Setup

1. Create a Firebase project and enable:
   - **Authentication** → Email/Password + Google
   - **Realtime Database** → Create database (test mode)

2. Register Android app with package `com.todoapp.todo_app`

3. Download `google-services.json` → place in `android/app/`

4. Update `lib/firebase_options.dart` with your credentials  
   *(or run `flutterfire configure`)*

5. Update `lib/core/constants.dart` with your Realtime DB URL:
   ```dart
   static const String databaseUrl = 'https://YOUR-PROJECT-rtdb.firebaseio.com';
   ```

6. In `android/app/build.gradle.kts`, uncomment:
   ```kotlin
   id("com.google.gms.google-services")
   ```

### Run the App

```bash
flutter pub get
flutter run                    # Android/emulator
flutter run -d chrome          # Web browser
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` `firebase_auth` | Firebase initialization & auth |
| `google_sign_in` | Google OAuth |
| `dio` | REST API calls to Firebase Realtime DB |
| `provider` | State management |
| `shared_preferences` | Offline local task storage |
| `google_fonts` | Poppins typography |
| `flutter_animate` | Smooth UI animations |
| `flutter_slidable` | Swipe-to-edit/delete gestures |
| `uuid` | Unique task IDs |

---

## 📸 Screenshots

> Add your screenshots here after running the app.

---

## 📄 License

MIT License — feel free to use, modify, and distribute.

---

> ⚠️ **Note:** `google-services.json` and sensitive Firebase credentials are excluded from this repo via `.gitignore`. Set up your own Firebase project using the steps above.
