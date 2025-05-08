import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photomerge/User/View/listimages.dart';
import 'package:shimmer/shimmer.dart';

class Mycategory extends StatefulWidget {
  final String categoryFilter;

  const Mycategory({Key? key, required this.categoryFilter}) : super(key: key);

  @override
  State<Mycategory> createState() => _MycategoryState();
}

class _MycategoryState extends State<Mycategory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final ScrollController _scrollController = ScrollController();
  String? _selectedSubcategory;
  List<String> _subcategories = ['All'];
  List<DocumentSnapshot> _documents = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
    _fetchImages();
    _scrollController.addListener(_scrollListener);
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for general alerts',
          importance: NotificationImportance.High,
          enableVibration: true,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchImages();
    }
  }

  Future<void> _fetchSubcategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('createdBy', isEqualTo: userId)
          .get();

      List<String> subcategories = [];
      for (var doc in snapshot.docs) {
        final categoryName = doc['name']?.toString().toLowerCase();
        if (categoryName == widget.categoryFilter.toLowerCase()) {
          subcategories = List<String>.from(doc['subcategories'] ?? []);
          break;
        }
      }

      if (subcategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            _subcategories = ['All', ...subcategories];
          });
        }
        return;
      }

      final imageSnapshot = await _firestore
          .collectionGroup('images')
          .where('category', isEqualTo: widget.categoryFilter)
          .get();

      final Set<String> subcategoriesSet = {'All'};
      for (var doc in imageSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('subcategory') && data['subcategory'] != null) {
          subcategoriesSet.add(data['subcategory'].toString());
        }
      }

      if (mounted) {
        setState(() {
          _subcategories = subcategoriesSet.toList()..sort();
        });
      }

      for (var doc in snapshot.docs) {
        if (doc['name'].toString().toLowerCase() ==
            widget.categoryFilter.toLowerCase()) {
          await _firestore.collection('categories').doc(doc.id).update({
            'subcategories': subcategoriesSet.toList()..remove('All'),
          });
          break;
        }
      }
    } catch (e) {
      print('Error fetching subcategories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching subcategories: $e')),
        );
      }
    }
  }

  Future<void> _fetchImages() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var query = _firestore
          .collectionGroup('images')
          .where('category', isEqualTo: widget.categoryFilter)
          .orderBy('timestamp', descending: true)
          .limit(_limit);

      if (_selectedSubcategory != null && _selectedSubcategory != 'All') {
        query = query.where('subcategory', isEqualTo: _selectedSubcategory);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      final newDocs = snapshot.docs;

      setState(() {
        _documents.addAll(newDocs);
        _lastDocument = newDocs.isNotEmpty ? newDocs.last : null;
        _hasMore = newDocs.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e')),
        );
      }
    }
  }

  Future<void> _refreshImages() async {
    setState(() {
      _documents.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text('${widget.categoryFilter} Photos',
            style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshImages,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = _subcategories[index];
                final isSelected = _selectedSubcategory == subcategory ||
                    (subcategory == 'All' && _selectedSubcategory == null);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(subcategory),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedSubcategory =
                              subcategory == 'All' ? null : subcategory;
                          _documents.clear();
                          _lastDocument = null;
                          _hasMore = true;
                        });
                        _fetchImages();
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _documents.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshImages,
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _documents.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _documents.length && _hasMore) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final photo =
                            _documents[index].data() as Map<String, dynamic>;
                        final photoId = _documents[index].id;
                        final photoUrl = photo['image_url'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageDetailView(
                                  photoId: photoId,
                                  photoUrl: photoUrl,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              memCacheHeight: 300,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.grey[300]),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error,
                                    size: 48, color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
