// File generated from google-services.json
// Project: bhargavi-milk  |  App ID: com.example.bhargavimilk

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      TargetPlatform.windows => web,
      _ => android,
    };
  }

  /// Web Configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCuXsl9E0l_ryIDfWOoYNNAxSJQ_6DaD9A',
    appId: '1:1014449057196:web:ff088347c95c530e635e09',
    messagingSenderId: '1014449057196',
    projectId: 'bhargavi-milk',
    authDomain: 'bhargavi-milk.firebaseapp.com',
    storageBucket: 'bhargavi-milk.firebasestorage.app',
  );

  /// Values taken directly from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuXsl9E0l_ryIDfWOoYNNAxSJQ_6DaD9A',
    appId: '1:1014449057196:android:ff088347c95c530e635e09',
    messagingSenderId: '1014449057196',
    projectId: 'bhargavi-milk',
    storageBucket: 'bhargavi-milk.firebasestorage.app',
  );

  /// iOS Configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuXsl9E0l_ryIDfWOoYNNAxSJQ_6DaD9A',
    appId: '1:1014449057196:ios:ff088347c95c530e635e09',
    messagingSenderId: '1014449057196',
    projectId: 'bhargavi-milk',
    storageBucket: 'bhargavi-milk.firebasestorage.app',
    iosBundleId: 'com.example.bhargavimilk',
  );
}
