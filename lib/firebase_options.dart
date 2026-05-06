import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('هاد الـ platform مش مدعوم');
    }
  }

  // ─── Web config ────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMhEoADwgKU8iNGmTD5rTQBA7Ns04DgdY',
    authDomain: 'garagego-7fbd5.firebaseapp.com',
    projectId: 'garagego-7fbd5',
    storageBucket: 'garagego-7fbd5.firebasestorage.app',
    messagingSenderId: '54366077263',
    appId: '1:54366077263:web:7b92fa8f760f49a917853a',
    measurementId: 'G-K96RS2MXTD',
  );

  // ─── Android config ─────────────────────────────────────────
  // هاد من google-services.json اللي عندك
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMhEoADwgKU8iNGmTD5rTQBA7Ns04DgdY',
    authDomain: 'garagego-7fbd5.firebaseapp.com',
    projectId: 'garagego-7fbd5',
    storageBucket: 'garagego-7fbd5.firebasestorage.app',
    messagingSenderId: '54366077263',
    appId: '1:54366077263:web:7b92fa8f760f49a917853a',
  );
}