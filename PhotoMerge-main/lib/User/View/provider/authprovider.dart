// AuthProvider for authentication and device management
import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as flutterSecureStorage;
import 'package:uuid/uuid.dart';

class AuthProviders with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentDeviceId;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  AuthProviders() {
    _initialize();
  }

  Future<void> _initialize() async {
    _currentDeviceId = await _getDeviceId();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        setupAutoLogoutListener();
      } else {
        _userDocSub?.cancel();
        _userDocSub = null;
      }
    });
    notifyListeners();
  }

  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor!;
      } else if (kIsWeb) {
        const storage = flutterSecureStorage.FlutterSecureStorage();
        String? deviceId = await storage.read(key: 'device_id');
        if (deviceId == null) {
          deviceId = Uuid().v4();
          await storage.write(key: 'device_id', value: deviceId);
        }
        return deviceId;
      }
      return 'unknown_device';
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  void setupAutoLogoutListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _userDocSub?.cancel(); // Cancel any existing subscription
    _userDocSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        await logout(); // Logout if user document is deleted
        return;
      }
      final data = snapshot.data() as Map<String, dynamic>;
      final serverDeviceId = data['deviceId'] ?? '';
      final isLoggedIn = data['isLoggedIn'] ?? false;

      if (isLoggedIn &&
          serverDeviceId != _currentDeviceId &&
          serverDeviceId.isNotEmpty) {
        await logout();
        notifyListeners();
      }
    }, onError: (error) {
      print('Error in auto logout listener: $error');
    });
  }

  Future<void> logout() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isLoggedIn': false,
          'deviceId': '',
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
      _userDocSub?.cancel();
      _userDocSub = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }
}
