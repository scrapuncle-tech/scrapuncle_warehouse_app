// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpw4mRbco2poiPVnEGogO015qkbNX1THc',
    appId: '1:894251245466:web:b8fdd231dd7ffde9592423',
    messagingSenderId: '894251245466',
    projectId: 'scrapuncle-452708',
    authDomain: 'scrapuncle-452708.firebaseapp.com',
    storageBucket: 'scrapuncle-452708.firebasestorage.app',
    measurementId: 'G-4HJT864YYL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAosIjIIM_3BtnZtKXFvZi7xSfd5LVVAVA',
    appId: '1:894251245466:android:9b66322ab9ef5dd2592423',
    messagingSenderId: '894251245466',
    projectId: 'scrapuncle-452708',
    storageBucket: 'scrapuncle-452708.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC08i2_UOl_svgUma2zRJIyjMLxhOSdx4g',
    appId: '1:894251245466:ios:f9347663a65c8b34592423',
    messagingSenderId: '894251245466',
    projectId: 'scrapuncle-452708',
    storageBucket: 'scrapuncle-452708.firebasestorage.app',
    iosClientId: '894251245466-jbrjmlr7f532g7tn0ko2cd0mt85slde5.apps.googleusercontent.com',
    iosBundleId: 'com.example.scrapuncleWarehouse',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC08i2_UOl_svgUma2zRJIyjMLxhOSdx4g',
    appId: '1:894251245466:ios:f9347663a65c8b34592423',
    messagingSenderId: '894251245466',
    projectId: 'scrapuncle-452708',
    storageBucket: 'scrapuncle-452708.firebasestorage.app',
    iosClientId: '894251245466-jbrjmlr7f532g7tn0ko2cd0mt85slde5.apps.googleusercontent.com',
    iosBundleId: 'com.example.scrapuncleWarehouse',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDpw4mRbco2poiPVnEGogO015qkbNX1THc',
    appId: '1:894251245466:web:8240018b6caaaf26592423',
    messagingSenderId: '894251245466',
    projectId: 'scrapuncle-452708',
    authDomain: 'scrapuncle-452708.firebaseapp.com',
    storageBucket: 'scrapuncle-452708.firebasestorage.app',
    measurementId: 'G-QHB0QV7KMR',
  );
}
