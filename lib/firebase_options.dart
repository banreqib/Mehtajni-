import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2FevOFhsC-w_UUuclbn0i39mf1xcYNXk',
    appId: '1:1031969093580:android:f4a6bd5967a5cf2feecf69',
    messagingSenderId: '1031969093580',
    projectId: 'flutter-chat-app-877f5',
    storageBucket: 'flutter-chat-app-877f5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDguMbdfJkIc_rOg1QGeVLJa2hB-aYei8I',
    appId: '1:1031969093580:ios:3f379aea8be1fa8feecf69',
    messagingSenderId: '1031969093580',
    projectId: 'flutter-chat-app-877f5',
    storageBucket: 'flutter-chat-app-877f5.firebasestorage.app',
    iosBundleId: 'com.example.subone',
  );
}
