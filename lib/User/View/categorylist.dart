import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photomerge/User/View/categorey.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final QuerySnapshot querySnapshot =
          await _firestore.collectionGroup('images').get();

      final Set<String> categories = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('category') && data['category'] != null) {
          categories.add(data['category'].toString());
        }
      }

      setState(() {
        _categories = categories.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _errorMessage = 'Failed to load categories';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchCategories,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _errorMessage != null
              ? _buildErrorWidget()
              : _categories.isEmpty
                  ? _buildEmptyWidget()
                  : _buildCategoryList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF4CAF50)),
          const SizedBox(height: 12),
          const Text(
            'Failed to load categories',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined,
              size: 48, color: Color(0xFF4CAF50)),
          const SizedBox(height: 12),
          const Text(
            'No categories available',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Mycategory(categoryFilter: category),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.photo_library,
                      size: 24, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Color(0xFF4CAF50)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
