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
    apiKey: 'AIzaSyBD3RarLj_696emYW84zZ1tliP_Th1z6mM',
    appId: '1:483086837036:web:2a6bf9084050ef399ef889',
    messagingSenderId: '483086837036',
    projectId: 'sham-coffee',
    authDomain: 'sham-coffee.firebaseapp.com',
    databaseURL: 'https://sham-coffee-default-rtdb.firebaseio.com',
    storageBucket: 'sham-coffee.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBD3RarLj_696emYW84zZ1tliP_Th1z6mM',
    appId: '1:483086837036:android:2a6bf9084050ef399ef889',
    messagingSenderId: '483086837036',
    projectId: 'sham-coffee',
    databaseURL: 'https://sham-coffee-default-rtdb.firebaseio.com',
    storageBucket: 'sham-coffee.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBD3RarLj_696emYW84zZ1tliP_Th1z6mM',
    appId: '1:483086837036:ios:2a6bf9084050ef399ef889',
    messagingSenderId: '483086837036',
    projectId: 'sham-coffee',
    databaseURL: 'https://sham-coffee-default-rtdb.firebaseio.com',
    storageBucket: 'sham-coffee.firebasestorage.app',
    iosBundleId: 'com.shamcoffee.shamCoffeeWorker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBD3RarLj_696emYW84zZ1tliP_Th1z6mM',
    appId: '1:483086837036:ios:2a6bf9084050ef399ef889',
    messagingSenderId: '483086837036',
    projectId: 'sham-coffee',
    databaseURL: 'https://sham-coffee-default-rtdb.firebaseio.com',
    storageBucket: 'sham-coffee.firebasestorage.app',
    iosBundleId: 'com.shamcoffee.shamCoffeeWorker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBD3RarLj_696emYW84zZ1tliP_Th1z6mM',
    appId: '1:483086837036:web:2a6bf9084050ef399ef889',
    messagingSenderId: '483086837036',
    projectId: 'sham-coffee',
    authDomain: 'sham-coffee.firebaseapp.com',
    databaseURL: 'https://sham-coffee-default-rtdb.firebaseio.com',
    storageBucket: 'sham-coffee.firebasestorage.app',
  );
}
