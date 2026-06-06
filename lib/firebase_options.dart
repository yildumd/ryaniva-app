import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATmdZdVMqlEw2EwOpymnGYoxmHbkze8eM',
    appId: '1:677473249156:android:d04d23b089aa19f2045fd1',
    messagingSenderId: '677473249156',
    projectId: 'ryaniva-4867f',
    storageBucket: 'ryaniva-4867f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATmdZdVMqlEw2EwOpymnGYoxmHbkze8eM',
    appId: '1:677473249156:android:d04d23b089aa19f2045fd1',
    messagingSenderId: '677473249156',
    projectId: 'ryaniva-4867f',
    storageBucket: 'ryaniva-4867f.firebasestorage.app',
  );
}