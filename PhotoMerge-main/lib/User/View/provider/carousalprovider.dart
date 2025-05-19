import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CarouselProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _imageUrls = [];
  int _currentIndex = 0;
  String? _errorMessage;

  List<String> get imageUrls => _imageUrls;
  int get currentIndex => _currentIndex;
  String? get errorMessage => _errorMessage;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> fetchCarouselImages() async {
    print("🔄 Fetching carousel images...");
    try {
      final doc =
          await _firestore.collection('carousel_images').doc('images').get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _imageUrls = (data['urls'] as List<dynamic>?)?.cast<String>() ?? [];
        _errorMessage = null;

        print("✅ Carousel images fetched: $_imageUrls");
      } else {
        _errorMessage = 'No carousel images available';
        _imageUrls = [];

        print("⚠️ Document 'carousel_images/images' does not exist.");
      }
    } catch (e) {
      _errorMessage = 'Error loading carousel images';
      _imageUrls = [];

      print("❌ Error fetching carousel images: $e");
    }

    notifyListeners();
  }
}
