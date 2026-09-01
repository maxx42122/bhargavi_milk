// File generated manually from google-services.json
// Project: bhargavi-milk  |  App ID: com.example.bhargavimilk

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not configured. Add web support via FlutterFire CLI.',
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => throw UnsupportedError(
        'iOS not configured. Add iOS support via FlutterFire CLI.',
      ),
      _ => throw UnsupportedError(
        'Unsupported platform: $defaultTargetPlatform',
      ),
    };
  }

  /// Values taken directly from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuXsl9E0l_ryIDfWOoYNNAxSJQ_6DaD9A',
    appId: '1:1014449057196:android:ff088347c95c530e635e09',
    messagingSenderId: '1014449057196',
    projectId: 'bhargavi-milk',
    storageBucket: 'bhargavi-milk.firebasestorage.app',
  );
}
