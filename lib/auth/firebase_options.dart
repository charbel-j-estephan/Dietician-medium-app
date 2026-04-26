// This file contains the Firebase options for the different platforms.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// This class holds the Firebase options for the different platforms.
class DefaultFirebaseOptions {
  // Returns the Firebase options for the current platform.
  static FirebaseOptions get currentPlatform {
    // If the app is running on the web, return the web options.
    if (kIsWeb) {
      return web;
    }
    // Otherwise, return the options for the current platform.
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Firebase options for the web platform.
  static final FirebaseOptions web = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
    appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN']!,
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET']!,
    measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID']!,
  );

  // Firebase options for the Android platform.
  static final FirebaseOptions android = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_ANDROID_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET']!,
  );

  // Firebase options for the iOS platform.
  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_MACOS_API_KEY']!,
    appId: dotenv.env['FIREBASE_IOS_MACOS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_IOS_MACOS_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_IOS_MACOS_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_IOS_MACOS_STORAGE_BUCKET']!,
    iosBundleId: dotenv.env['FIREBASE_IOS_MACOS_BUNDLE_ID']!,
  );

  // Firebase options for the macOS platform.
  static final FirebaseOptions macos = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_MACOS_API_KEY']!,
    appId: dotenv.env['FIREBASE_IOS_MACOS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_IOS_MACOS_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_IOS_MACOS_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_IOS_MACOS_STORAGE_BUCKET']!,
    iosBundleId: dotenv.env['FIREBASE_IOS_MACOS_BUNDLE_ID']!,
  );

  // Firebase options for the Windows platform.
  static final FirebaseOptions windows = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WINDOWS_API_KEY']!,
    appId: dotenv.env['FIREBASE_WINDOWS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WINDOWS_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_WINDOWS_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WINDOWS_AUTH_DOMAIN']!,
    storageBucket: dotenv.env['FIREBASE_WINDOWS_STORAGE_BUCKET']!,
    measurementId: dotenv.env['FIREBASE_WINDOWS_MEASUREMENT_ID']!,
  );
}
