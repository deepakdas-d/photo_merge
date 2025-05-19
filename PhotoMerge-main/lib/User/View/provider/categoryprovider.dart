// CategoriesProvider for category data
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _categories = [];
  String? _errorMessage;

  List<QueryDocumentSnapshot> get categories => _categories;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    try {
      final snapshot =
          await _firestore.collection('categories').orderBy('name').get();
      _categories = snapshot.docs;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading categories';
    }
    notifyListeners();
  }
}
