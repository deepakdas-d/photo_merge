import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  Map<String, dynamic>? get userData => _userData;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserData(String? userId) async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists) {
        _userData = doc.data();
        _errorMessage = null;
      } else {
        _errorMessage = 'User data not found';
      }
    } catch (e) {
      _errorMessage = 'Error fetching user data: $e';
    }
    notifyListeners();
  }
}
