// File generated by FlutterFire CLI. Do not modify.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// A default instance of this class must be defined as [DefaultFirebaseOptions.currentPlatform]
/// before calling `Firebase.initializeApp()`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Note: You'll need to add configurations for Android/iOS separately.
    // This can be done by running `flutterfire configure` or manually adding them.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZku_umeY0AXt_IyG6Y898RKHfpL2rw7E',
    appId: '1:546254001513:web:c9b63734564a66474899f8',
    messagingSenderId: '546254001513',
    projectId: 'jengamate',
    authDomain: 'jengamate.firebaseapp.com',
    storageBucket: 'jengamate.firebasestorage.app',
    measurementId: 'G-F1FP84T3E7',
  );
}
