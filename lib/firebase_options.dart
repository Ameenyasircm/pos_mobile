import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyALYOZy1RuYR9wVwn3uO-GuG9eM6b_HRs0',
    appId: '1:111340213053:android:0287533d040c0902fe6b54',
    messagingSenderId: '111340213053',
    projectId: 'pos-system-95357',
    storageBucket: 'pos-system-95357.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALYOZy1RuYR9wVwn3uO-GuG9eM6b_HRs0',
    appId: '1:111340213053:android:0287533d040c0902fe6b54',
    messagingSenderId: '111340213053',
    projectId: 'pos-system-95357',
    storageBucket: 'pos-system-95357.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyALYOZy1RuYR9wVwn3uO-GuG9eM6b_HRs0',
    appId: '1:111340213053:android:0287533d040c0902fe6b54',
    messagingSenderId: '111340213053',
    projectId: 'pos-system-95357',
    storageBucket: 'pos-system-95357.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyALYOZy1RuYR9wVwn3uO-GuG9eM6b_HRs0',
    appId: '1:111340213053:android:0287533d040c0902fe6b54',
    messagingSenderId: '111340213053',
    projectId: 'pos-system-95357',
    storageBucket: 'pos-system-95357.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyALYOZy1RuYR9wVwn3uO-GuG9eM6b_HRs0',
    appId: '1:111340213053:android:0287533d040c0902fe6b54',
    messagingSenderId: '111340213053',
    projectId: 'pos-system-95357',
    storageBucket: 'pos-system-95357.firebasestorage.app',
  );
}
