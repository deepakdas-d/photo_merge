import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateVideoPage extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic> videoData;

  const UpdateVideoPage({
    super.key,
    required this.videoId,
    required this.videoData,
  });

  @override
  State<UpdateVideoPage> createState() => _UpdateVideoPageState();
}

class _UpdateVideoPageState extends State<UpdateVideoPage> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedCategory;
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
  void initState() {
    super.initState();
    // Pre-populate fields with existing data
    _urlController.text = widget.videoData['url'] ?? '';
    _nameController.text = widget.videoData['name'] ?? '';
    _selectedCategory = widget.videoData['category'] ?? _categories[0];
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateVideo() async {
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
      // Update video in Firestore
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .update({
        'url': url,
        'name': name,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video updated successfully')),
      );
      Navigator.pop(context); // Return to VideoListPage
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating video: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Update YouTube Video',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update YouTube Video',
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
                prefixIcon: const Icon(Icons.title, color: Color(0xFF4CAF50)),
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
                prefixIcon: const Icon(Icons.link, color: Color(0xFF4CAF50)),
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
                    const Icon(Icons.category, color: Color(0xFF4CAF50)),
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
                    onPressed: _updateVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
