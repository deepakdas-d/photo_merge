import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:photomerge/User/View/imagedetails.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class ListImages extends StatefulWidget {
  const ListImages({Key? key}) : super(key: key);

  @override
  State<ListImages> createState() => _ListImagesState();
}

class _ListImagesState extends State<ListImages> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
  List<DocumentSnapshot> _documents = [];
  bool _isLoading = false;
  bool _hasMore = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchImages();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _fetchImages();
      });
    }
  }

  Future<void> _fetchImages() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore
          .collectionGroup('images')
          .orderBy('timestamp', descending: true)
          .limit(_limit);

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
      print('Error loading more images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more images: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Gallery',
          style: GoogleFonts.poppins(
            color: const Color(0xFF00A19A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserDashboard(),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF00A19A),
        ),
      ),
      body: _documents.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _documents.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                await _fetchImages();
              },
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _documents.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _documents.length && _hasMore) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final photo =
                      _documents[index].data() as Map<String, dynamic>;
                  final photoId = _documents[index].id;
                  final photoUrl = photo['image_url'];

                  return GestureDetector(
                    onTap: () {
                      // Precache the full-size image before navigating
                      precacheImage(
                        CachedNetworkImageProvider(photo['image_url']),
                        context,
                      ).then((_) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    ImageDetailView(
                              photoId: photoId,
                              photoUrl: photo['image_url'],
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 30),
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 200,
                        memCacheWidth: 200,
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
    );
  }
}
