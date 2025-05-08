// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:lottie/lottie.dart';
// import 'dart:ui' as ui;
// import 'dart:io';

// class ImageDetailView extends StatefulWidget {
//   final String photoId;
//   final String photoUrl;

//   const ImageDetailView(
//       {Key? key, required this.photoId, required this.photoUrl})
//       : super(key: key);

//   @override
//   State<ImageDetailView> createState() => _ImageDetailViewState();
// }

// class _ImageDetailViewState extends State<ImageDetailView>
//     with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;
//   Map<String, dynamic>? userData;
//   final GlobalKey _cardKey = GlobalKey();
//   Color _backgroundColor = Colors.grey.shade800;
//   final Map<String, Color> _dominantColors = {};
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   // Constants
//   static const double pixelRatio = 2.0;
//   static const double a4Width = 1653.0;
//   static const double a4Height = 2339.0;
//   static const int maxColorCount = 16;
//   static const double fadeHeight = 100.0;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     )..forward();
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _getUserData();
//     _fetchDominantColor();
//     AwesomeNotifications().initialize(
//       null,
//       [
//         NotificationChannel(
//           channelKey: 'basic_channel',
//           channelName: 'Basic Notifications',
//           channelDescription: 'Notification channel for basic notifications',
//           defaultColor: const Color(0xFF4CAF50),
//           ledColor: Colors.white,
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _dominantColors.clear();
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

//   Future<void> _fetchDominantColor() async {
//     final color = await _getDominantColor(widget.photoUrl);
//     setState(() => _backgroundColor = color);
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
//     bool hasPermission = true;
//     if (Platform.isAndroid) {
//       final deviceInfo = DeviceInfoPlugin();
//       final androidInfo = await deviceInfo.androidInfo;
//       final sdkInt = androidInfo.version.sdkInt;

//       if (sdkInt < 33) {
//         final status = await Permission.storage.request();
//         hasPermission = status.isGranted;
//         if (!hasPermission && status.isPermanentlyDenied) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Text(
//                     'Storage permission is permanently denied. Please enable it in app settings.'),
//                 action: SnackBarAction(
//                   label: 'Settings',
//                   onPressed: () => openAppSettings(),
//                 ),
//               ),
//             );
//           }
//         } else if (!hasPermission) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Storage permission denied')),
//             );
//           }
//         }
//       } else {
//         final status = await Permission.photos.request();
//         hasPermission = status.isGranted;
//         if (!hasPermission && status.isPermanentlyDenied) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Text(
//                     'Photo access permission is permanently denied. Please enable it in app settings.'),
//                 action: SnackBarAction(
//                   label: 'Settings',
//                   onPressed: () => openAppSettings(),
//                 ),
//               ),
//             );
//           }
//         } else if (!hasPermission) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Photo access permission denied')),
//             );
//           }
//         }
//       }
//     }

//     if (!hasPermission) return;

//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       if (!userDoc.exists) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User data not found')),
//           );
//         }
//         return;
//       }

//       final userData = userDoc.data()!;
//       final bool freeDownloadUsed = userData['freeDownloadUsed'] ?? false;
//       final bool isSubscribed = userData['isSubscribed'] ?? false;
//       final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

//       bool hasActiveSubscription = isSubscribed && subscriptionExpiry != null;
//       if (hasActiveSubscription &&
//           !subscriptionExpiry!.toDate().isAfter(DateTime.now())) {
//         await _firestore.collection('users').doc(userId).update({
//           'isSubscribed': false,
//         });
//         hasActiveSubscription = false;
//       }

//       if (isSubscribed && subscriptionExpiry == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text(
//                     'Subscription data is incomplete. Please contact support.')),
//           );
//         }
//         return;
//       }

//       if (!freeDownloadUsed || hasActiveSubscription) {
//         try {
//           if (mounted) {
//             showDialog(
//               context: context,
//               barrierDismissible: false,
//               builder: (context) => const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             );
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Processing image...')),
//             );
//           }

//           final boundary = _cardKey.currentContext?.findRenderObject()
//               as RenderRepaintBoundary?;
//           if (boundary == null) {
//             if (mounted) {
//               Navigator.pop(context); // Dismiss loader
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                     content: Text('Cannot capture image at this time')),
//               );
//             }
//             return;
//           }

//           // Capture the content
//           final image = await boundary.toImage(pixelRatio: pixelRatio);
//           final byteData =
//               await image.toByteData(format: ui.ImageByteFormat.png);
//           if (byteData == null) {
//             if (mounted) Navigator.pop(context); // Dismiss loader
//             throw Exception('Failed to capture image data');
//           }

//           final codec =
//               await ui.instantiateImageCodec(byteData.buffer.asUint8List());
//           final frameInfo = await codec.getNextFrame();

//           // Create A4 canvas
//           final recorder = ui.PictureRecorder();
//           final canvas = Canvas(recorder);

//           // Draw the image to fill the entire A4 page
//           canvas.drawImageRect(
//             frameInfo.image,
//             Rect.fromLTWH(
//                 0, 0, image.width.toDouble(), image.height.toDouble()),
//             Rect.fromLTWH(0, 0, a4Width, a4Height),
//             Paint()..filterQuality = FilterQuality.high,
//           );

//           // Convert to PNG
//           final picture = recorder.endRecording();
//           final a4Image =
//               await picture.toImage(a4Width.toInt(), a4Height.toInt());
//           final a4ByteData =
//               await a4Image.toByteData(format: ui.ImageByteFormat.png);
//           final a4PngBytes = a4ByteData!.buffer.asUint8List();

//           // Save the image
//           await FlutterImageGallerySaver.saveImage(a4PngBytes);

//           if (!mounted) return;
//           Navigator.pop(context); // Dismiss loader
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Image saved to gallery!'),
//               behavior: SnackBarBehavior.floating,
//             ),
//           );

//           if (!freeDownloadUsed && !hasActiveSubscription) {
//             await _firestore.collection('users').doc(userId).update({
//               'freeDownloadUsed': true,
//               'lastSubscriptionUpdate': Timestamp.now(),
//             });
//           }
//         } catch (e) {
//           print('Error saving image: $e');
//           if (mounted) {
//             Navigator.pop(context); // Dismiss loader
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error saving image: $e')),
//             );
//           }
//         }
//       } else {
//         if (mounted) Navigator.pop(context); // Dismiss loader if shown
//         await _showNotification(
//           title: 'Subscription Expired',
//           body:
//               'Your subscription plan has expired. Please renew to continue downloading images.',
//         );
//         if (mounted) {
//           _showSubscriptionDialog();
//         }
//       }
//     } catch (e) {
//       print('Error checking user subscription: $e');
//       if (mounted) {
//         Navigator.pop(context); // Dismiss loader if shown
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _shareImage(String photoId, String photoUrl) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(userId).get();
//       if (!userDoc.exists) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('User data not found')),
//           );
//         }
//         return;
//       }

//       final userData = userDoc.data()!;
//       final bool isSubscribed = userData['isSubscribed'] ?? false;
//       final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

//       bool hasActiveSubscription = isSubscribed && subscriptionExpiry != null;
//       if (hasActiveSubscription &&
//           !subscriptionExpiry!.toDate().isAfter(DateTime.now())) {
//         await _firestore.collection('users').doc(userId).update({
//           'isSubscribed': false,
//         });
//         hasActiveSubscription = false;
//       }

//       if (isSubscribed && subscriptionExpiry == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text(
//                     'Subscription data is incomplete. Please contact support.')),
//           );
//         }
//         return;
//       }

//       if (hasActiveSubscription) {
//         try {
//           if (mounted) {
//             showDialog(
//               context: context,
//               barrierDismissible: false,
//               builder: (context) => const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             );
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Preparing image for sharing...')),
//             );
//           }

//           final boundary = _cardKey.currentContext?.findRenderObject()
//               as RenderRepaintBoundary?;
//           if (boundary == null) {
//             if (mounted) {
//               Navigator.pop(context); // Dismiss loader
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                     content: Text('Cannot capture image at this time')),
//               );
//             }
//             return;
//           }

//           final image = await boundary.toImage(pixelRatio: pixelRatio);
//           final byteData =
//               await image.toByteData(format: ui.ImageByteFormat.png);
//           if (byteData == null) {
//             if (mounted) Navigator.pop(context); // Dismiss loader
//             throw Exception('Failed to capture image data');
//           }

//           final tempDir = await Directory.systemTemp.createTemp();
//           final tempFile = File('${tempDir.path}/share_image_$photoId.png');
//           await tempFile.writeAsBytes(byteData.buffer.asUint8List());

//           await Share.shareXFiles(
//             [XFile(tempFile.path)],
//             text: 'Check out this image from PhotoMerge!',
//           );

//           // Clean up
//           await tempFile.delete();

//           if (!mounted) return;
//           Navigator.pop(context); // Dismiss loader
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Image shared successfully!'),
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         } catch (e) {
//           print('Error sharing image: $e');
//           if (mounted) {
//             Navigator.pop(context); // Dismiss loader
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error sharing image: $e')),
//             );
//           }
//         }
//       } else {
//         if (mounted) Navigator.pop(context); // Dismiss loader if shown
//         await _showNotification(
//           title: 'Subscription Required',
//           body: 'Please subscribe to share images. Choose a plan to continue.',
//         );
//         if (mounted) {
//           _showSubscriptionDialog();
//         }
//       }
//     } catch (e) {
//       print('Error checking user subscription: $e');
//       if (mounted) {
//         Navigator.pop(context); // Dismiss loader if shown
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _showNotification(
//       {required String title, required String body}) async {
//     if (Platform.isAndroid) {
//       final deviceInfo = DeviceInfoPlugin();
//       final androidInfo = await deviceInfo.androidInfo;
//       final sdkInt = androidInfo.version.sdkInt;

//       if (sdkInt >= 33) {
//         final status = await Permission.notification.request();
//         if (!status.isGranted) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Text(
//                     'Notification permission denied. Please enable it in settings.'),
//                 action: SnackBarAction(
//                   label: 'Settings',
//                   onPressed: () => openAppSettings(),
//                 ),
//               ),
//             );
//           }
//           return;
//         }
//       }
//     }

//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: DateTime.now().millisecondsSinceEpoch % 10000,
//         channelKey: 'basic_channel',
//         title: title,
//         body: body,
//         notificationLayout: NotificationLayout.Default,
//       ),
//     );
//   }

//   void _showSubscriptionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Subscription Required'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'You need an active subscription to share images. Please choose a subscription plan.',
//               ),
//               const SizedBox(height: 16),
//               _buildPlanOption('Standard Plan', 300, 'month'),
//               _buildPlanOption('Premium Plan', 1000, 'year'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPlanOption(String planName, int price, String duration) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       child: ListTile(
//         title: Text(planName),
//         subtitle: Text('\₹$price/$duration'),
//         trailing: const Icon(Icons.arrow_forward),
//         onTap: () => _redirectToWhatsApp(planName, price, duration),
//       ),
//     );
//   }

//   Future<void> _redirectToWhatsApp(
//       String plan, int price, String duration) async {
//     const adminWhatsAppNumber = '+919567725398';
//     final message =
//         'Hello, I want to subscribe to the $plan (\₹$price/$duration) for the PhotoMerge app.';
//     final encodedMessage = Uri.encodeComponent(message);

//     final whatsappUrl =
//         'https://wa.me/$adminWhatsAppNumber?text=$encodedMessage';
//     final uri = Uri.parse(whatsappUrl);

//     try {
//       if (await canLaunchUrl(uri)) {
//         final launched = await launchUrl(
//           uri,
//           mode: LaunchMode.externalApplication,
//         );
//         if (!launched && mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text(
//                     'Could not open WhatsApp. Please ensure WhatsApp is installed.')),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content:
//                     Text('WhatsApp is not installed or cannot be opened.')),
//           );
//         }
//         final fallbackUrl =
//             'whatsapp://send?phone=$adminWhatsAppNumber&text=$encodedMessage';
//         final fallbackUri = Uri.parse(fallbackUrl);
//         if (await canLaunchUrl(fallbackUri)) {
//           await launchUrl(fallbackUri);
//         }
//       }
//     } catch (e) {
//       print('Error launching WhatsApp: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to open WhatsApp: $e')),
//         );
//       }
//     }

//     if (mounted) {
//       Navigator.pop(context);
//     }
//   }

//   Widget _buildPhotoCard(
//       String photoId, String photoUrl, Color backgroundColor) {
//     // Show Lottie animation filling the card while color is being fetched
//     if (backgroundColor == Colors.grey.shade800) {
//       return Card(
//         elevation: 6,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//         clipBehavior: Clip.antiAlias,
//         child: Lottie.asset(
//           'assets/image_grid_loading.json',
//           fit: BoxFit.cover,
//           height: 600, // Approximate height to match card
//         ),
//       );
//     }

//     return AnimatedBuilder(
//       animation: _fadeAnimation,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
//           child: Opacity(
//             opacity: _fadeAnimation.value,
//             child: child,
//           ),
//         );
//       },
//       child: Card(
//         elevation: 6,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           children: [
//             RepaintBoundary(
//               key: _cardKey,
//               child: Column(
//                 children: [
//                   AspectRatio(
//                     aspectRatio: 4 / 5,
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         CachedNetworkImage(
//                           imageUrl: photoUrl,
//                           fit: BoxFit.cover,
//                           memCacheHeight: 1200,
//                           placeholder: (context, url) => Shimmer.fromColors(
//                             baseColor: Colors.grey[300]!,
//                             highlightColor: Colors.grey[100]!,
//                             child: Container(color: Colors.grey[300]),
//                           ),
//                           errorWidget: (context, url, error) {
//                             print('Image load error for $url: $error');
//                             return Container(
//                               color: Colors.grey[200],
//                               child: const Center(
//                                 child: Icon(Icons.error,
//                                     size: 48, color: Colors.red),
//                               ),
//                             );
//                           },
//                         ),
//                         Positioned.fill(
//                           child: CustomPaint(
//                             painter: WatermarkPainter(userData: userData),
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
//                                   backgroundColor.withOpacity(0.1),
//                                   backgroundColor.withOpacity(0.3),
//                                   backgroundColor.withOpacity(0.5),
//                                   backgroundColor.withOpacity(0.7),
//                                   backgroundColor.withOpacity(0.9),
//                                   backgroundColor,
//                                 ],
//                                 stops: const [
//                                   0.0,
//                                   0.2,
//                                   0.4,
//                                   0.6,
//                                   0.8,
//                                   0.9,
//                                   1.0
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (userData != null)
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 12, horizontal: 12),
//                       decoration: BoxDecoration(
//                         color: backgroundColor,
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Container(
//                                 width: 48,
//                                 height: 48,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.white.withOpacity(0.7),
//                                     width: 2,
//                                   ),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.2),
//                                       blurRadius: 4,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(10),
//                                   child: userData!['userImage'] != null
//                                       ? CachedNetworkImage(
//                                           imageUrl: userData!['userImage'],
//                                           fit: BoxFit.cover,
//                                           placeholder: (context, url) =>
//                                               Container(
//                                             color:
//                                                 Colors.white.withOpacity(0.2),
//                                             child: const Center(
//                                               child: CircularProgressIndicator(
//                                                   strokeWidth: 2),
//                                             ),
//                                           ),
//                                           errorWidget: (context, url, error) =>
//                                               Container(
//                                             color:
//                                                 Colors.white.withOpacity(0.2),
//                                             child: const Icon(Icons.person,
//                                                 size: 32, color: Colors.white),
//                                           ),
//                                         )
//                                       : Container(
//                                           color: Colors.white.withOpacity(0.2),
//                                           child: const Icon(Icons.person,
//                                               size: 32, color: Colors.white),
//                                         ),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Padding(
//                                   padding:
//                                       const EdgeInsets.symmetric(horizontal: 8),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         userData!['firstName'] ??
//                                             'Unknown User',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 14,
//                                           color: Colors.white,
//                                           shadows: [
//                                             Shadow(
//                                               offset: Offset(0, 1),
//                                               blurRadius: 2,
//                                               color:
//                                                   Color.fromARGB(80, 0, 0, 0),
//                                             ),
//                                           ],
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         userData!['designation'] ??
//                                             'No designation',
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.white70,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         userData!['phone1'] ?? 'No Number',
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.white70,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         userData!['email'] ?? 'No email',
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.white70,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               if (userData!['companyLogo'] != null &&
//                                   userData!['companyLogo'].isNotEmpty)
//                                 Container(
//                                   width: 48,
//                                   height: 48,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: Colors.white.withOpacity(0.2),
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.7),
//                                       width: 1,
//                                     ),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.2),
//                                         blurRadius: 3,
//                                         offset: const Offset(0, 1),
//                                       ),
//                                     ],
//                                   ),
//                                   child: ClipOval(
//                                     child: CachedNetworkImage(
//                                       imageUrl: userData!['companyLogo'],
//                                       fit: BoxFit.cover,
//                                       placeholder: (context, url) =>
//                                           const Center(
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: Colors.white54,
//                                         ),
//                                       ),
//                                       errorWidget: (context, url, error) =>
//                                           const Icon(
//                                         Icons.business,
//                                         size: 24,
//                                         color: Colors.white70,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(height: 8),
//                           if (userData!['companyWebsite'] != null &&
//                               userData!['companyWebsite'].toString().isNotEmpty)
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   vertical: 8, horizontal: 8),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   userData!['companyWebsite'],
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.white,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(14),
//                   bottomRight: Radius.circular(14),
//                 ),
//               ),
//               padding: const EdgeInsets.all(12),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextButton.icon(
//                       icon: const Icon(Icons.download,
//                           size: 20, color: Colors.white),
//                       label: const Text(
//                         'Download',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       style: TextButton.styleFrom(
//                         backgroundColor: backgroundColor,
//                         minimumSize: const Size(double.infinity, 48),
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                       ),
//                       onPressed: () => _captureAndSaveImage(photoId, photoUrl),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextButton.icon(
//                       icon: const Icon(Icons.share,
//                           size: 20, color: Colors.white),
//                       label: const Text(
//                         'Share',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       style: TextButton.styleFrom(
//                         backgroundColor: backgroundColor,
//                         minimumSize: const Size(double.infinity, 48),
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                       ),
//                       onPressed: () => _shareImage(photoId, photoUrl),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF4CAF50),
//         title:
//             const Text('Image Details', style: TextStyle(color: Colors.white)),
//       ),
//       body: userData == null
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: _buildPhotoCard(
//                     widget.photoId, widget.photoUrl, _backgroundColor),
//               ),
//             ),
//     );
//   }
// }

// class WatermarkPainter extends CustomPainter {
//   final Map<String, dynamic>? userData;

//   WatermarkPainter({this.userData});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: userData?['firstName'] != null
//             ? '${userData!['firstName']} Maxgrow'
//             : 'Maxgrow',
//         style: const TextStyle(color: Colors.white70, fontSize: 10),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, const Offset(8, 8));
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui' as ui;
import 'dart:io';

class ImageDetailView extends StatefulWidget {
  final String photoId;
  final String photoUrl;

  const ImageDetailView(
      {Key? key, required this.photoId, required this.photoUrl})
      : super(key: key);

  @override
  State<ImageDetailView> createState() => _ImageDetailViewState();
}

class _ImageDetailViewState extends State<ImageDetailView>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;
  final GlobalKey _cardKey = GlobalKey();
  Color _backgroundColor = Colors.grey.shade800;
  final Map<String, Color> _dominantColors = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoadingColor = true; // Flag to track color loading status

  // Constants
  static const double pixelRatio = 2.0;
  static const double a4Width = 1653.0;
  static const double a4Height = 2339.0;
  static const int maxColorCount = 16;
  static const double fadeHeight = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _getUserData();
    _fetchDominantColor();
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic notifications',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: Colors.white,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dominantColors.clear();
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

  Future<void> _fetchDominantColor() async {
    setState(() => _isLoadingColor = true);
    try {
      final color = await _getDominantColor(widget.photoUrl);
      if (mounted) {
        setState(() {
          _backgroundColor = color;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      print('Error in _fetchDominantColor: $e');
      if (mounted) {
        setState(() => _isLoadingColor = false);
      }
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
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing image...')),
            );
          }

          final boundary = _cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            if (mounted) {
              Navigator.pop(context); // Dismiss loader
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cannot capture image at this time')),
              );
            }
            return;
          }

          // Capture the content
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) {
            if (mounted) Navigator.pop(context); // Dismiss loader
            throw Exception('Failed to capture image data');
          }

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
          Navigator.pop(context); // Dismiss loader
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
            Navigator.pop(context); // Dismiss loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving image: $e')),
            );
          }
        }
      } else {
        if (mounted) Navigator.pop(context); // Dismiss loader if shown
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
        Navigator.pop(context); // Dismiss loader if shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareImage(String photoId, String photoUrl) async {
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

      if (hasActiveSubscription) {
        try {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preparing image for sharing...')),
            );
          }

          final boundary = _cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            if (mounted) {
              Navigator.pop(context); // Dismiss loader
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cannot capture image at this time')),
              );
            }
            return;
          }

          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) {
            if (mounted) Navigator.pop(context); // Dismiss loader
            throw Exception('Failed to capture image data');
          }

          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/share_image_$photoId.png');
          await tempFile.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles(
            [XFile(tempFile.path)],
            text: 'Check out this image from PhotoMerge!',
          );

          // Clean up
          await tempFile.delete();

          if (!mounted) return;
          Navigator.pop(context); // Dismiss loader
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image shared successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          print('Error sharing image: $e');
          if (mounted) {
            Navigator.pop(context); // Dismiss loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sharing image: $e')),
            );
          }
        }
      } else {
        if (mounted) Navigator.pop(context); // Dismiss loader if shown
        await _showNotification(
          title: 'Subscription Required',
          body: 'Please subscribe to share images. Choose a plan to continue.',
        );
        if (mounted) {
          _showSubscriptionDialog();
        }
      }
    } catch (e) {
      print('Error checking user subscription: $e');
      if (mounted) {
        Navigator.pop(context); // Dismiss loader if shown
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
                'You need an active subscription to share images. Please choose a subscription plan.',
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
    // Show Lottie animation while color is being fetched
    if (_isLoadingColor) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image is still loaded in background
                  CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: 1200,
                    placeholder: (context, url) =>
                        Container(color: Colors.black12),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, size: 48, color: Colors.red),
                      ),
                    ),
                  ),
                  // Overlay with color extraction animation
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Use a color extraction themed Lottie animation
                          Lottie.asset(
                            'assets/color_loading.json', // You'll need to add this Lottie file
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Extracting colors...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Placeholder for user info during loading
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
              ),
              height: 120, // Fixed height for the shimmer effect
              child: Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[600]!,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 12,
                                  width: 120,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 10,
                                  width: 100,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 10,
                                  width: 140,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 24,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            // Placeholder buttons
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show actual content once color is loaded
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 1200,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.grey[300]),
                          ),
                          errorWidget: (context, url, error) {
                            print('Image load error for $url: ');
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error,
                                    size: 48, color: Colors.red),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WatermarkPainter(userData: userData),
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
                                  backgroundColor.withOpacity(0.1),
                                  backgroundColor.withOpacity(0.3),
                                  backgroundColor.withOpacity(0.5),
                                  backgroundColor.withOpacity(0.7),
                                  backgroundColor.withOpacity(0.9),
                                  backgroundColor,
                                ],
                                stops: const [
                                  0.0,
                                  0.2,
                                  0.4,
                                  0.6,
                                  0.8,
                                  0.9,
                                  1.0
                                ],
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.7),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: userData!['userImage'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: userData!['userImage'],
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            child: const Center(
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white70,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white70,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white.withOpacity(0.2),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white70,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData!['userName'] ?? 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userData!['userEmail'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Created with PhotoMerge',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              userData!['bio'] ??
                                  'Premium AI-generated artwork',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _captureAndSaveImage(photoId, photoUrl),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _shareImage(photoId, photoUrl),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Photo Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About this Image'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This image was created using PhotoMerge AI.'),
                      SizedBox(height: 12),
                      Text(
                        'Download to save a high-quality version to your device. '
                        'Share option is available for subscribers only.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildPhotoCard(widget.photoId, widget.photoUrl, _backgroundColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final Map<String, dynamic>? userData;

  WatermarkPainter({this.userData});

  @override
  void paint(Canvas canvas, Size size) {
    if (userData == null || userData!['watermarkEnabled'] != true) return;

    final String watermarkText = userData!['watermarkText'] ?? 'PhotoMerge';
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeCap = StrokeCap.round;

    final textStyle = ui.TextStyle(
      color: Colors.white.withOpacity(0.3),
      fontSize: 16,
      fontWeight: ui.FontWeight.bold,
    );

    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
    );

    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(watermarkText);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width - 40));

    final textSize = Size(
      paragraph.maxIntrinsicWidth,
      paragraph.height,
    );

    // Draw diagonal watermarks
    for (double i = -size.height; i < size.height * 2; i += 100) {
      canvas.save();
      canvas.translate(size.width / 2, i);
      canvas.rotate(-0.3); // Slight diagonal angle
      canvas.translate(-textSize.width / 2, 0);
      canvas.drawParagraph(paragraph, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
