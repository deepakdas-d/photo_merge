// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:ui' as ui;
// import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'package:shimmer/shimmer.dart';

// class ListImages extends StatefulWidget {
//   const ListImages({Key? key}) : super(key: key);

//   @override
//   State<ListImages> createState() => _ListImagesState();
// }

// class _ListImagesState extends State<ListImages> with TickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;
//   Map<String, dynamic>? userData;

//   // Cached maps for performance
//   final Map<String, GlobalKey> _photoKeys = {};
//   final Map<String, Color> _dominantColors = {};
//   final Map<String, AnimationController> _animationControllers = {};

//   // Pagination variables
//   static const int _pageSize = 10;
//   DocumentSnapshot? _lastDocument;
//   bool _isLoadingMore = false;
//   bool _hasMoreData = true;
//   final List<QueryDocumentSnapshot> _images = [];

//   // Layout toggle
//   bool _isGridView = false;

//   // Constants
//   static const String imagesSubcollection = 'images';
//   static const double fadeHeight = 120.0;
//   static const int maxColorCount = 8;
//   static const double pixelRatio = 2.0;

//   @override
//   void initState() {
//     super.initState();
//     _getUserData();
//     _loadInitialImages();
//   }

//   @override
//   void dispose() {
//     _animationControllers.forEach((key, controller) {
//       controller.dispose();
//     });
//     super.dispose();
//   }

//   Future<void> _getUserData() async {
//     if (userId == null) return;
//     try {
//       final doc = await _firestore.collection('user_profile').doc(userId).get();
//       if (doc.exists) {
//         setState(() => userData = doc.data());
//       }
//     } catch (e) {
//       print('Error fetching user data: $e');
//     }
//   }

//   Future<void> _loadInitialImages() async {
//     if (_isLoadingMore) return;
//     setState(() => _isLoadingMore = true);

//     try {
//       final query = _firestore
//           .collectionGroup(imagesSubcollection)
//           .orderBy('timestamp', descending: true)
//           .limit(_pageSize);

//       final snapshot = await query.get();
//       setState(() {
//         _images.addAll(snapshot.docs);
//         _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
//         _hasMoreData = snapshot.docs.length == _pageSize;
//         _isLoadingMore = false;
//       });

//       for (var doc in snapshot.docs) {
//         _createAnimationController(doc.id);
//       }
//     } catch (e) {
//       print('Error loading images: $e');
//       setState(() => _isLoadingMore = false);
//     }
//   }

//   Future<void> _loadMoreImages() async {
//     if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
//     setState(() => _isLoadingMore = true);

//     try {
//       final query = _firestore
//           .collectionGroup(imagesSubcollection)
//           .orderBy('timestamp', descending: true)
//           .startAfterDocument(_lastDocument!)
//           .limit(_pageSize);

//       final snapshot = await query.get();
//       setState(() {
//         _images.addAll(snapshot.docs);
//         _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
//         _hasMoreData = snapshot.docs.length == _pageSize;
//         _isLoadingMore = false;
//       });

//       for (var doc in snapshot.docs) {
//         _createAnimationController(doc.id);
//       }
//     } catch (e) {
//       print('Error loading more images: $e');
//       setState(() => _isLoadingMore = false);
//     }
//   }

//   void _createAnimationController(String id) {
//     if (!_animationControllers.containsKey(id)) {
//       final controller = AnimationController(
//         duration: const Duration(milliseconds: 300),
//         vsync: this,
//       );
//       _animationControllers[id] = controller;
//       Future.delayed(
//           Duration(milliseconds: 50 * _animationControllers.length % 10), () {
//         if (mounted && controller.isAnimating != true) {
//           controller.forward();
//         }
//       });
//     }
//   }

//   Future<Color> _getDominantColor(String imageUrl) async {
//     if (_dominantColors.containsKey(imageUrl)) {
//       return _dominantColors[imageUrl]!;
//     }
//     try {
//       final paletteGenerator = await PaletteGenerator.fromImageProvider(
//         NetworkImage(imageUrl),
//         size: const Size(80, 80),
//         maximumColorCount: maxColorCount,
//       );
//       final color = paletteGenerator.vibrantColor?.color ??
//           paletteGenerator.dominantColor?.color ??
//           Colors.grey.shade800;
//       final HSLColor hsl = HSLColor.fromColor(color);
//       final adjustedColor =
//           hsl.lightness > 0.7 ? hsl.withLightness(0.6).toColor() : color;
//       _dominantColors[imageUrl] = adjustedColor;
//       return adjustedColor;
//     } catch (e) {
//       print('Error getting dominant color for $imageUrl: $e');
//       return Colors.grey.shade800;
//     }
//   }

//   Future<void> _captureAndSaveImage(String photoId, String photoUrl) async {
//     final status = await Permission.storage.request();
//     if (!status.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Storage permission denied')),
//       );
//       return;
//     }

//     final key = _photoKeys[photoId];
//     if (key == null || key.currentContext == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Cannot capture image at this time')),
//       );
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Processing image...')),
//     );

//     try {
//       final boundary =
//           key.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       // A4 dimensions in pixels at 300 DPI (scaled for performance)
//       const double a4Width = 2480.0;
//       const double a4Height = 3508.0;

//       // Capture the content
//       final image = await boundary.toImage(pixelRatio: pixelRatio);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       if (byteData == null) throw Exception('Failed to capture image data');

//       final codec =
//           await ui.instantiateImageCodec(byteData.buffer.asUint8List());
//       final frameInfo = await codec.getNextFrame();

//       // Create A4 canvas
//       final recorder = ui.PictureRecorder();
//       final canvas = Canvas(recorder);

//       // Draw the image to fill the entire A4 page
//       canvas.drawImageRect(
//         frameInfo.image,
//         Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
//         Rect.fromLTWH(0, 0, a4Width, a4Height),
//         Paint()..filterQuality = FilterQuality.high,
//       );

//       // Convert to PNG
//       final picture = recorder.endRecording();
//       final a4Image = await picture.toImage(a4Width.toInt(), a4Height.toInt());
//       final a4ByteData =
//           await a4Image.toByteData(format: ui.ImageByteFormat.png);
//       final a4PngBytes = a4ByteData!.buffer.asUint8List();

//       // Save the image
//       await FlutterImageGallerySaver.saveImage(a4PngBytes);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Image saved to gallery!'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       print('Error saving image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error saving image')),
//       );
//     }
//   }

//   Widget _buildPhotoCard(
//       String photoId, String photoUrl, Color backgroundColor) {
//     if (!_photoKeys.containsKey(photoId)) {
//       _photoKeys[photoId] = GlobalKey();
//     }

//     final AnimationController animController = _animationControllers[photoId] ??
//         AnimationController(duration: Duration.zero, vsync: this)
//       ..forward();
//     final Animation<double> fadeAnimation = CurvedAnimation(
//       parent: animController,
//       curve: Curves.easeInOut,
//     );

//     return AnimatedBuilder(
//       animation: fadeAnimation,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, 20 * (1 - fadeAnimation.value)),
//           child: Opacity(
//             opacity: fadeAnimation.value,
//             child: child,
//           ),
//         );
//       },
//       child: Card(
//         key: ValueKey(photoId),
//         elevation: 4, // Elevation for display only
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12)), // Rounded for display
//         margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//         child: Column(
//           children: [
//             // RepaintBoundary captures the content without rounded corners
//             RepaintBoundary(
//               key: _photoKeys[photoId],
//               child: Column(
//                 children: [
//                   // Image section
//                   AspectRatio(
//                     aspectRatio: 4 / 5,
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Hero(
//                           tag: 'photo_$photoId',
//                           child: CachedNetworkImage(
//                             imageUrl: photoUrl,
//                             fit: BoxFit.cover,
//                             width: double.infinity,
//                             placeholder: (context, url) => Shimmer.fromColors(
//                               baseColor: Colors.grey[300]!,
//                               highlightColor: Colors.grey[100]!,
//                               child: Container(color: Colors.grey[300]),
//                             ),
//                             errorWidget: (context, url, error) {
//                               print('Image load error for $url: $error');
//                               return const Icon(Icons.error, size: 48);
//                             },
//                           ),
//                         ),
//                         Positioned.fill(
//                           child: CustomPaint(
//                             painter: WatermarkPainter(),
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           left: 0,
//                           right: 0,
//                           height: fadeHeight,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                                 colors: [
//                                   Colors.transparent,
//                                   backgroundColor.withOpacity(0.3),
//                                   backgroundColor.withOpacity(0.6),
//                                   backgroundColor.withOpacity(0.9),
//                                   backgroundColor,
//                                 ],
//                                 stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // User info section
//                   if (userData != null)
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: backgroundColor,
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.7),
//                                 width: 2,
//                               ),
//                             ),
//                             child: CircleAvatar(
//                               radius: 28,
//                               backgroundColor: Colors.white.withOpacity(0.2),
//                               backgroundImage: userData!['userImage'] != null
//                                   ? NetworkImage(userData!['userImage'])
//                                   : null,
//                               child: userData!['userImage'] == null
//                                   ? const Icon(Icons.person,
//                                       size: 28, color: Colors.white)
//                                   : null,
//                             ),
//                           ),
//                           Expanded(
//                             child: Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(horizontal: 16),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     userData!['firstName'] ?? 'Unknown User',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 18,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   Text(
//                                     userData!['designation'] ??
//                                         'No designation',
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       color: Colors.white70,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.email,
//                                           size: 14, color: Colors.white70),
//                                       const SizedBox(width: 6),
//                                       Expanded(
//                                         child: Text(
//                                           userData!['email'] ?? 'No email',
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.white70,
//                                           ),
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           if (userData!['companyLogo'] != null &&
//                               userData!['companyLogo'].isNotEmpty)
//                             Container(
//                               width: 64,
//                               height: 64,
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.9),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: CachedNetworkImage(
//                                 imageUrl: userData!['companyLogo'],
//                                 fit: BoxFit.contain,
//                                 placeholder: (context, url) =>
//                                     const CircularProgressIndicator(),
//                                 errorWidget: (context, error, stackTrace) =>
//                                     const Icon(Icons.error),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             // Simplified download button
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: TextButton.icon(
//                 icon: const Icon(Icons.download, size: 20, color: Colors.white),
//                 label: const Text('Download',
//                     style: TextStyle(color: Colors.white)),
//                 style: TextButton.styleFrom(
//                   backgroundColor: backgroundColor,
//                   minimumSize: const Size(double.infinity, 44),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 onPressed: () => _captureAndSaveImage(photoId, photoUrl),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGridView() {
//     return NotificationListener<ScrollNotification>(
//       onNotification: (notification) {
//         if (notification is ScrollEndNotification &&
//             notification.metrics.extentAfter < 500) {
//           _loadMoreImages();
//         }
//         return false;
//       },
//       child: GridView.builder(
//         padding: const EdgeInsets.all(12),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 0.7,
//         ),
//         itemCount: _images.length + (_hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == _images.length) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           final photo = _images[index].data() as Map<String, dynamic>;
//           final photoId = _images[index].id;
//           final photoUrl = photo['image_url'] ?? '';
//           return FutureBuilder<Color>(
//             future: _getDominantColor(photoUrl),
//             builder: (context, colorSnapshot) {
//               if (!colorSnapshot.hasData) {
//                 return Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 );
//               }
//               return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildListView() {
//     return NotificationListener<ScrollNotification>(
//       onNotification: (notification) {
//         if (notification is ScrollEndNotification &&
//             notification.metrics.extentAfter < 500) {
//           _loadMoreImages();
//         }
//         return false;
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: _images.length + (_hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == _images.length) {
//             return const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: CircularProgressIndicator(),
//               ),
//             );
//           }
//           final photo = _images[index].data() as Map<String, dynamic>;
//           final photoId = _images[index].id;
//           final photoUrl = photo['image_url'] ?? '';
//           return FutureBuilder<Color>(
//             future: _getDominantColor(photoUrl),
//             builder: (context, colorSnapshot) {
//               if (!colorSnapshot.hasData) {
//                 return Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Container(
//                     height: 400,
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 );
//               }
//               return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
//             },
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF4CAF50),
//         title: const Text('Photo Gallery',
//             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 _images.clear();
//                 _lastDocument = null;
//                 _hasMoreData = true;
//                 _animationControllers.forEach((key, controller) {
//                   controller.dispose();
//                 });
//                 _animationControllers.clear();
//               });
//               _loadInitialImages();
//               _getUserData();
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.grey.shade100, Colors.grey.shade200],
//           ),
//         ),
//         child: userData == null
//             ? const Center(child: CircularProgressIndicator())
//             : _isGridView
//                 ? _buildGridView()
//                 : _buildListView(),
//       ),
//     );
//   }
// }

// class WatermarkPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.2)
//       ..style = PaintingStyle.fill;

//     final textPainter = TextPainter(
//       text: const TextSpan(
//         text: 'Maxgrow',
//         style: TextStyle(
//           color: Colors.white70,
//           fontSize: 30,
//           fontWeight: FontWeight.w600,
//           letterSpacing: 1.0,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );

//     textPainter.layout();
//     canvas.save();
//     canvas.translate(size.width / 2, size.height / 2);
//     canvas.rotate(-45 * 3.14159 / 180);
//     canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
//     textPainter.paint(canvas, Offset.zero);
//     canvas.restore();
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ListImages extends StatefulWidget {
  const ListImages({Key? key}) : super(key: key);

  @override
  State<ListImages> createState() => _ListImagesState();
}

class _ListImagesState extends State<ListImages> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;

  // Cached maps for performance
  final Map<String, GlobalKey> _photoKeys = {};
  final Map<String, Color> _dominantColors = {};
  final Map<String, AnimationController> _animationControllers = {};

  // Pagination variables
  static const int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final List<QueryDocumentSnapshot> _images = [];

  // Layout toggle
  bool _isGridView = false;

  // Constants
  static const String imagesSubcollection = 'images';
  static const double fadeHeight = 120.0;
  static const int maxColorCount = 8;
  static const double pixelRatio = 2.0;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadInitialImages();
    // Initialize AwesomeNotifications
    AwesomeNotifications().initialize(
      null, // No default icon
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
    _animationControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _getUserData() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists) {
        setState(() => userData = doc.data());
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _loadInitialImages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final query = _firestore
          .collectionGroup(imagesSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();
      setState(() {
        _images.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreData = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });

      for (var doc in snapshot.docs) {
        _createAnimationController(doc.id);
      }
    } catch (e) {
      print('Error loading images: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadMoreImages() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final query = _firestore
          .collectionGroup(imagesSubcollection)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();
      setState(() {
        _images.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreData = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });

      for (var doc in snapshot.docs) {
        _createAnimationController(doc.id);
      }
    } catch (e) {
      print('Error loading more images: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _createAnimationController(String id) {
    if (!_animationControllers.containsKey(id)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _animationControllers[id] = controller;
      Future.delayed(
          Duration(milliseconds: 50 * _animationControllers.length % 10), () {
        if (mounted && controller.isAnimating != true) {
          controller.forward();
        }
      });
    }
  }

  Future<Color> _getDominantColor(String imageUrl) async {
    if (_dominantColors.containsKey(imageUrl)) {
      return _dominantColors[imageUrl]!;
    }
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(80, 80),
        maximumColorCount: maxColorCount,
      );
      final color = paletteGenerator.vibrantColor?.color ??
          paletteGenerator.dominantColor?.color ??
          Colors.grey.shade800;
      final HSLColor hsl = HSLColor.fromColor(color);
      final adjustedColor =
          hsl.lightness > 0.7 ? hsl.withLightness(0.6).toColor() : color;
      _dominantColors[imageUrl] = adjustedColor;
      return adjustedColor;
    } catch (e) {
      print('Error getting dominant color for $imageUrl: $e');
      return Colors.grey.shade800;
    }
  }

  Future<void> _captureAndSaveImage(String photoId, String photoUrl) async {
    bool hasPermission = true;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt < 33) {
        final status = await Permission.storage.request();
        hasPermission = status.isGranted;
        if (!hasPermission && status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Storage permission is permanently denied. Please enable it in app settings.'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
        } else if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
          }
        }
      } else {
        final status = await Permission.photos.request();
        hasPermission = status.isGranted;
        if (!hasPermission && status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Photo access permission is permanently denied. Please enable it in app settings.'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
        } else if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo access permission denied')),
            );
          }
        }
      }
    }

    if (!hasPermission) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
        }
        return;
      }

      final userData = userDoc.data()!;
      final bool freeDownloadUsed = userData['freeDownloadUsed'] ?? false;
      final bool isSubscribed = userData['isSubscribed'] ?? false;
      final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

      bool hasActiveSubscription = isSubscribed && subscriptionExpiry != null;
      if (hasActiveSubscription &&
          !subscriptionExpiry!.toDate().isAfter(DateTime.now())) {
        await _firestore.collection('users').doc(userId).update({
          'isSubscribed': false,
        });
        hasActiveSubscription = false;
      }

      if (isSubscribed && subscriptionExpiry == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Subscription data is incomplete. Please contact support.')),
          );
        }
        return;
      }

      if (!freeDownloadUsed || hasActiveSubscription) {
        try {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing image...')),
            );
          }

          final key = _photoKeys[photoId];
          if (key == null || key.currentContext == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cannot capture image at this time')),
              );
            }
            return;
          }

          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          // A4 dimensions in pixels at 300 DPI (scaled for performance)
          const double a4Width = 2480.0;
          const double a4Height = 3508.0;

          // Capture the content
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) throw Exception('Failed to capture image data');

          final codec =
              await ui.instantiateImageCodec(byteData.buffer.asUint8List());
          final frameInfo = await codec.getNextFrame();

          // Create A4 canvas
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);

          // Draw the image to fill the entire A4 page
          canvas.drawImageRect(
            frameInfo.image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(0, 0, a4Width, a4Height),
            Paint()..filterQuality = FilterQuality.high,
          );

          // Convert to PNG
          final picture = recorder.endRecording();
          final a4Image =
              await picture.toImage(a4Width.toInt(), a4Height.toInt());
          final a4ByteData =
              await a4Image.toByteData(format: ui.ImageByteFormat.png);
          final a4PngBytes = a4ByteData!.buffer.asUint8List();

          // Save the image
          await FlutterImageGallerySaver.saveImage(a4PngBytes);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery!'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          if (!freeDownloadUsed && !hasActiveSubscription) {
            await _firestore.collection('users').doc(userId).update({
              'freeDownloadUsed': true,
              'lastSubscriptionUpdate': Timestamp.now(),
            });
          }
        } catch (e) {
          print('Error saving image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving image: $e')),
            );
          }
        }
      } else {
        await _showNotification(
          title: 'Subscription Expired',
          body:
              'Your subscription plan has expired. Please renew to continue downloading images.',
        );
        if (mounted) {
          _showSubscriptionDialog();
        }
      }
    } catch (e) {
      print('Error checking user subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showNotification(
      {required String title, required String body}) async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Notification permission denied. Please enable it in settings.'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You have used your free download. Please choose a subscription plan to continue downloading images.',
              ),
              const SizedBox(height: 16),
              _buildPlanOption('Standard Plan', 300, 'month'),
              _buildPlanOption('Premium Plan', 1000, 'year'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String planName, int price, String duration) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(planName),
        subtitle: Text('\₹$price/$duration'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _redirectToWhatsApp(planName, price, duration),
      ),
    );
  }

  Future<void> _redirectToWhatsApp(
      String plan, int price, String duration) async {
    const adminWhatsAppNumber = '+919567725398';
    final message =
        'Hello, I want to subscribe to the $plan (\₹$price/$duration) for the PhotoMerge app.';
    final encodedMessage = Uri.encodeComponent(message);

    final whatsappUrl =
        'https://wa.me/$adminWhatsAppNumber?text=$encodedMessage';
    final uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not open WhatsApp. Please ensure WhatsApp is installed.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('WhatsApp is not installed or cannot be opened.')),
          );
        }
        final fallbackUrl =
            'whatsapp://send?phone=$adminWhatsAppNumber&text=$encodedMessage';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open WhatsApp: $e')),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildPhotoCard(
      String photoId, String photoUrl, Color backgroundColor) {
    if (!_photoKeys.containsKey(photoId)) {
      _photoKeys[photoId] = GlobalKey();
    }

    final AnimationController animController = _animationControllers[photoId] ??
        AnimationController(duration: Duration.zero, vsync: this)
      ..forward();
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - fadeAnimation.value)),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        key: ValueKey(photoId),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            RepaintBoundary(
              key: _photoKeys[photoId],
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'photo_$photoId',
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.grey[300]),
                            ),
                            errorWidget: (context, url, error) {
                              print('Image load error for $url: $error');
                              return const Icon(Icons.error, size: 48);
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WatermarkPainter(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: fadeHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  backgroundColor.withOpacity(0.3),
                                  backgroundColor.withOpacity(0.6),
                                  backgroundColor.withOpacity(0.9),
                                  backgroundColor,
                                ],
                                stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (userData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.7),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: userData!['userImage'] != null
                                  ? NetworkImage(userData!['userImage'])
                                  : null,
                              child: userData!['userImage'] == null
                                  ? const Icon(Icons.person,
                                      size: 28, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData!['firstName'] ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    userData!['designation'] ??
                                        'No designation',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.email,
                                          size: 14, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          userData!['email'] ?? 'No email',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (userData!['companyLogo'] != null &&
                              userData!['companyLogo'].isNotEmpty)
                            Container(
                              width: 74,
                              height: 7,
                              padding: EdgeInsets.all(9),
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage:
                                    userData!['companyLogo'] != null
                                        ? NetworkImage(userData!['companyLogo'])
                                        : null,
                                child: userData!['companyLogo'] == null
                                    ? const Icon(Icons.person,
                                        size: 28, color: Colors.white)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                icon: const Icon(Icons.download, size: 20, color: Colors.white),
                label: const Text('Download',
                    style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                  backgroundColor: backgroundColor,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _captureAndSaveImage(photoId, photoUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 500) {
          _loadMoreImages();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _images.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final photo = _images[index].data() as Map<String, dynamic>;
          final photoId = _images[index].id;
          final photoUrl = photo['image_url'] ?? '';
          return FutureBuilder<Color>(
            future: _getDominantColor(photoUrl),
            builder: (context, colorSnapshot) {
              if (!colorSnapshot.hasData) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
              return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 500) {
          _loadMoreImages();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _images.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final photo = _images[index].data() as Map<String, dynamic>;
          final photoId = _images[index].id;
          final photoUrl = photo['image_url'] ?? '';
          return FutureBuilder<Color>(
            future: _getDominantColor(photoUrl),
            builder: (context, colorSnapshot) {
              if (!colorSnapshot.hasData) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 400,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
              return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4CAF50),
        title: const Text('Photo Gallery',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _images.clear();
                _lastDocument = null;
                _hasMoreData = true;
                _animationControllers.forEach((key, controller) {
                  controller.dispose();
                });
                _animationControllers.clear();
              });
              _loadInitialImages();
              _getUserData();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade200],
          ),
        ),
        child: userData == null
            ? const Center(child: CircularProgressIndicator())
            : _isGridView
                ? _buildGridView()
                : _buildListView(),
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Maxgrow',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-45 * 3.14159 / 180);
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
