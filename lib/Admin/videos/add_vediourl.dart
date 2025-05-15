import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AddVediourl extends StatefulWidget {
  const AddVediourl({super.key});

  @override
  State<AddVediourl> createState() => _AddVediourlState();
}

class _AddVediourlState extends State<AddVediourl> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _selectedCategory; // Store selected category
  bool _isLoading = false;

  // List of categories for the dropdown
  final List<String> _categories = [
    'Tutorial',
    'Entertainment',
    'Vlog',
    'Gaming',
    'Music',
    'Other',
  ];

  // Regular expression for validating YouTube URLs
  final _youtubeUrlPattern = RegExp(
    r'^(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})(.*)?$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitUrl() async {
    final url = _urlController.text.trim();
    final name = _nameController.text.trim();
    final category = _selectedCategory;

    // Validate inputs
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a video name')),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube URL')),
      );
      return;
    }

    if (!_youtubeUrlPattern.hasMatch(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid YouTube URL')),
      );
      return;
    }

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      // Store URL, name, category, and userId in Firestore
      await _firestore.collection('videos').add({
        'url': url,
        'name': name,
        'category': category,
        'userId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('YouTube video added successfully')),
      );
      _urlController.clear();
      _nameController.clear();
      setState(() {
        _selectedCategory = null; // Reset category
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding video: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Add YouTube Video',
            style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
          ),
          backgroundColor: Color(0xFF00B6B0),
        ),
        body: const Center(
          child: Text('Please sign in to add YouTube videos'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add YouTube Video',
          style: GoogleFonts.oswald(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 25),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/adminlistvedio');
              },
              icon: Icon(
                Icons.list,
                color: Colors.white,
              ))
        ],
        backgroundColor: Color(0xFF00B6B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add YouTube Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Video Name',
                hintText: 'e.g., My Vacation Video',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title, color: Color(0xFF00B6B0)),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'e.g., https://www.youtube.com/watch?v=abc123',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF00B6B0)),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: const OutlineInputBorder(),
                prefixIcon:
                    const Icon(Icons.category, color: Color(0xFF00B6B0)),
              ),
              hint: const Text('Select a category'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submitUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00B6B0),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
