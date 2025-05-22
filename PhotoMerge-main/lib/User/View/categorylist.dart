// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
// import 'package:photomerge/User/View/categorey.dart';
// import 'package:photomerge/User/View/home.dart';

// class CategoryListPage extends StatefulWidget {
//   const CategoryListPage({Key? key}) : super(key: key);

//   @override
//   State<CategoryListPage> createState() => _CategoryListPageState();
// }

// class _CategoryListPageState extends State<CategoryListPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> _categories = [];
//   bool _isLoading = true;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCategories();
//   }

//   Future<void> _fetchCategories() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });

//       final QuerySnapshot querySnapshot =
//           await _firestore.collection('categories').orderBy('name').get();

//       final List<Map<String, dynamic>> categories =
//           querySnapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {
//           'name': data['name']?.toString() ?? 'Category ${doc.id}',
//           'image_url': data['image_url']?.toString() ?? '',
//         };
//       }).toList();

//       setState(() {
//         _categories = categories;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching categories: $e');
//       setState(() {
//         _errorMessage = 'Failed to load categories';
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Text(
//           'Categories',
//           style: GoogleFonts.poppins(
//             color: Color(0xFF00A19A),
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         leading: IconButton(
//           onPressed: () {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => UserDashboard(),
//                 ));
//           },
//           icon: Icon(
//             Icons.arrow_back,
//           ),
//           color: Color(0xFF00A19A),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _fetchCategories,
//         backgroundColor: const Color(0xFF00A19A),
//         child: const Icon(Icons.refresh, color: Colors.white),
//       ),
//       backgroundColor: Colors.white,
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
//           : _errorMessage != null
//               ? _buildErrorWidget()
//               : _categories.isEmpty
//                   ? _buildEmptyWidget()
//                   : _buildCategoryList(),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 48, color: Color(0xFF4CAF50)),
//           const SizedBox(height: 12),
//           const Text(
//             'Failed to load categories',
//             style: TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _fetchCategories,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4CAF50),
//             ),
//             child: const Text(
//               'Retry',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.category_outlined,
//               size: 48, color: Color(0xFF4CAF50)),
//           const SizedBox(height: 12),
//           const Text(
//             'No categories available',
//             style: TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _fetchCategories,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4CAF50),
//             ),
//             child: const Text(
//               'Refresh',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategoryList() {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       itemCount: _categories.length,
//       itemBuilder: (context, index) {
//         final category = _categories[index];
//         final categoryName = category['name'] as String;
//         final imageUrl = category['image_url'] as String;

//         // Create a unique color for each category based on index
//         final colors = [
//           const Color(0xFF4CAF50), // Green
//           const Color(0xFF2196F3), // Blue
//           const Color(0xFFF44336), // Red
//           const Color(0xFFFF9800), // Orange
//           const Color(0xFF9C27B0), // Purple
//           const Color(0xFF00BCD4), // Cyan
//         ];
//         final color = colors[index % colors.length];

//         return Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white,
//                 color.withOpacity(0.08),
//               ],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(0.15),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//                 spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             borderRadius: BorderRadius.circular(16),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(16),
//               splashColor: color.withOpacity(0.1),
//               highlightColor: color.withOpacity(0.05),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         Mycategory(categoryFilter: categoryName),
//                   ),
//                 );
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(18),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 68,
//                       height: 68,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             color.withOpacity(0.8),
//                             color,
//                           ],
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: color.withOpacity(0.25),
//                             blurRadius: 8,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: imageUrl.isNotEmpty
//                             ? CachedNetworkImage(
//                                 imageUrl: imageUrl,
//                                 width: 68,
//                                 height: 68,
//                                 fit: BoxFit.cover,
//                                 placeholder: (context, url) => Container(
//                                   color: Colors.transparent,
//                                   child: Center(
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                           Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                                 errorWidget: (context, url, error) => Container(
//                                   color: Colors.transparent,
//                                   child: const Icon(
//                                     Icons.category_rounded,
//                                     color: Colors.white,
//                                     size: 32,
//                                   ),
//                                 ),
//                               )
//                             : Container(
//                                 color: Colors.transparent,
//                                 child: const Icon(
//                                   Icons.category_rounded,
//                                   color: Colors.white,
//                                   size: 32,
//                                 ),
//                               ),
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             categoryName,
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                               letterSpacing: 0.2,
//                               color: Color(0xFF2D3142),
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.shopping_bag_outlined,
//                                 size: 14,
//                                 color: color,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 'Browse collection',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w500,
//                                   color: color,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       width: 42,
//                       height: 42,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         color: Colors.white,
//                         boxShadow: [
//                           BoxShadow(
//                             color: color.withOpacity(0.15),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         Icons.arrow_forward_ios_rounded,
//                         size: 16,
//                         color: color,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/categorey.dart';
import 'package:photomerge/User/View/home.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({Key? key}) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CategoryModel> _categories = [];
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
          await _firestore.collection('categories').orderBy('name').get();

      final List<CategoryModel> categories = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CategoryModel(
          name: data['name']?.toString() ?? 'Category ${doc.id}',
          imageUrl: data['image_url']?.toString() ?? '',
        );
      }).toList();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
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
        title: Text(
          'Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Color(0xFF00A19A),
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
          ),
          icon: const Icon(Icons.arrow_back),
          color: Color(0xFF00A19A),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchCategories,
        backgroundColor: Color(0xFF00A19A),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return _buildErrorWidget();
    } else if (_categories.isEmpty) {
      return _buildEmptyWidget();
    } else {
      return _buildCategoryList();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(height: 12),
          Text(
            'Failed to load categories',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchCategories,
            child: const Text('Retry'),
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
          Icon(Icons.category_outlined,
              size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(height: 12),
          Text(
            'No categories available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchCategories,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return CategoryListItem(
          category: category,
          index: index,
          onTap: () => _navigateToCategory(category.name),
        );
      },
    );
  }

  void _navigateToCategory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Mycategory(categoryFilter: categoryName),
      ),
    );
  }
}

class CategoryListItem extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final VoidCallback onTap;

  const CategoryListItem({
    Key? key,
    required this.category,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a unique color for each category based on index
    final colors = [
      Theme.of(context).primaryColor,
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildCategoryImage(color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Browse collection',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImage(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: category.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: category.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.category,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.category,
                color: Colors.grey,
                size: 24,
              ),
      ),
    );
  }
}

class CategoryModel {
  final String name;
  final String imageUrl;

  CategoryModel({
    required this.name,
    required this.imageUrl,
  });
}
