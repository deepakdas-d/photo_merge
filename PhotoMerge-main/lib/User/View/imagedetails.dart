import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photomerge/User/View/listimages.dart';
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

  static const double pixelRatio = 5.0; // Increased from 3.0 for higher quality
  static const double a4Width = 3540.0; // 4K resolution width
  static const double a4Height = 5424.0; // Maintains A4 aspect ratio (1:1.414)
  static const int maxColorCount = 16;
  static const double fadeHeight = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 5000),
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
    final color = await _getDominantColor(widget.photoUrl);
    setState(() => _backgroundColor = color);
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
          !subscriptionExpiry.toDate().isAfter(DateTime.now())) {
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

          final boundary = _cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            if (mounted) {
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

  Widget _buildPhotoCard(
      String photoId, String photoUrl, Color backgroundColor) {
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
                            print('Image load error for $url: $error');
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
                          child: Center(
                            child: CustomPaint(
                              painter: WatermarkPainter(userData: userData),
                            ),
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
                          vertical: 8, horizontal: 10), // Reduced padding
                      decoration: BoxDecoration(
                        color: backgroundColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 82,
                                height: 85,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(4), // Adjusted
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 3, // Adjusted
                                      offset: const Offset(0, 1), // Adjusted
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: userData!['userImage'] != null &&
                                          userData!['userImage']
                                              .toString()
                                              .isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: userData!['userImage'],
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1.5), // Adjusted
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            child: const Icon(Icons.person,
                                                size: 28,
                                                color:
                                                    Colors.white), // Adjusted
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white.withOpacity(0.2),
                                          child: const Icon(Icons.person,
                                              size: 28,
                                              color: Colors.white), // Adjusted
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6), // Reduced from 8
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData!['firstName'] ?? 'Unknown User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13, // Reduced from 14
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Color.fromARGB(80, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      userData!['designation'] ??
                                          'No designation',
                                      style: const TextStyle(
                                        fontSize: 11, // Reduced from 12
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      userData!['phone'] ?? 'No Number',
                                      style: const TextStyle(
                                        fontSize: 11, // Reduced from 12
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      userData!['email'] ?? 'No email',
                                      style: const TextStyle(
                                        fontSize: 10, // Reduced from 12
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      userData!['companyWebsite'] ??
                                          "No Website",
                                      style: const TextStyle(
                                        fontSize: 11, // Reduced from 12
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (userData!['companyLogo'] != null &&
                                  userData!['companyLogo']
                                      .toString()
                                      .isNotEmpty)
                                Container(
                                  width: 55, // Reduced from 50
                                  height: 55, // Reduced from 50
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: userData!['companyLogo'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5, // Adjusted
                                          color: Colors.white54,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                        Icons.business,
                                        size: 20, // Reduced from 24
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                    child: TextButton.icon(
                      icon: const Icon(Icons.download,
                          size: 18, color: Colors.white), // Adjusted
                      label: const Text(
                        'Download',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Adjusted
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: backgroundColor,
                        minimumSize:
                            const Size(double.infinity, 44), // Adjusted
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)), // Adjusted
                      ),
                      onPressed: () => _captureAndSaveImage(photoId, photoUrl),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.share,
                          size: 18, color: Colors.white), // Adjusted
                      label: const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Adjusted
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: backgroundColor,
                        minimumSize:
                            const Size(double.infinity, 44), // Adjusted
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)), // Adjusted
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
          !subscriptionExpiry.toDate().isAfter(DateTime.now())) {
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preparing image for sharing...')),
            );
          }

          final boundary = _cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            if (mounted) {
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
          if (byteData == null) throw Exception('Failed to capture image data');

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image shared successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          print('Error sharing image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sharing image: $e')),
            );
          }
        }
      } else {
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
    const adminWhatsAppNumber = '+918075601175';
    final message =
        'Hello, I want to subscribe to the $plan (\₹$price/$duration) for the BrandBuilder app.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Image Details',
          style: GoogleFonts.poppins(
            color: Color(0xFF00A19A),
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
                  builder: (context) => ListImages(),
                ));
          },
          icon: Icon(
            Icons.arrow_back,
          ),
          color: Color(0xFF00A19A),
        ),
      ),
      body: FutureBuilder(
        future: Future.delayed(Duration(seconds: 3)), // Delay for 3 seconds
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loader while waiting
            return Center(
              child: Lottie.asset(
                'assets/animations/image_generating.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            );
          } else {
            // Show the photo card content after delay
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhotoCard(
                    widget.photoId, widget.photoUrl, _backgroundColor),
              ),
            );
          }
        },
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final Map<String, dynamic>? userData;

  WatermarkPainter({this.userData});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: userData?['companyName'] != null
            ? '${userData!['companyName']} '
            : 'BrandBuilders',
        style: const TextStyle(
            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(8, 8));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
