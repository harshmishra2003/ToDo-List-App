import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Auto-filled from google-services.json
// Firebase Project: login-ff68f
// Package: com.example.login

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuXkIduTMNwJUijE4wS_i45A5issPjRWg',
    appId: '1:377972901757:android:eccc459cb356d39c96ee14',
    messagingSenderId: '377972901757',
    projectId: 'login-ff68f',
    storageBucket: 'login-ff68f.firebasestorage.app',
    // TODO: Set your Realtime Database URL if different from the default
    databaseURL: 'https://login-ff68f-default-rtdb.firebaseio.com',
  );

  // TODO: Add your Web app config here if using flutter run -d chrome
  // Register a Web app in Firebase Console > Project Settings > Add app > Web
  // Then replace these placeholder values
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCuXkIduTMNwJUijE4wS_i45A5issPjRWg',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '377972901757',
    projectId: 'login-ff68f',
    authDomain: 'login-ff68f.firebaseapp.com',
    databaseURL: 'https://login-ff68f-default-rtdb.firebaseio.com',
    storageBucket: 'login-ff68f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuXkIduTMNwJUijE4wS_i45A5issPjRWg',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '377972901757',
    projectId: 'login-ff68f',
    databaseURL: 'https://login-ff68f-default-rtdb.firebaseio.com',
    storageBucket: 'login-ff68f.firebasestorage.app',
    iosClientId:
        '377972901757-lneuqal9glcdcjtsdjor7dp4duj250po.apps.googleusercontent.com',
    iosBundleId: 'com.example.login',
  );
}
