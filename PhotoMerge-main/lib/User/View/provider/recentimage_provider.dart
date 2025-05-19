// RecentImagesProvider for recent images
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RecentImagesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _images = [];
  String? _errorMessage;

  List<QueryDocumentSnapshot> get images => _images;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecentImages() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('images')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      _images = snapshot.docs;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading images';
    }
    notifyListeners();
  }
}
