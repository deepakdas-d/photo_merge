import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:io';

// ViewModel for managing ImageDetailView state
class ImageDetailViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;
  Color _backgroundColor = Colors.grey.shade800;
  final Map<String, Color> _dominantColors = {};
  bool _isLoading = true;
  String? _error;

  Color get backgroundColor => _backgroundColor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ImageDetailViewModel(String photoUrl) {
    _initialize(photoUrl);
  }

  Future<void> _initialize(String photoUrl) async {
    await Future.wait([
      _initializeNotifications(),
      _getUserData(),
      _fetchDominantColor(photoUrl),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initializeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
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
    } catch (e) {
      print('Error initializing notifications: $e');
      _error = 'Failed to initialize notifications';
      notifyListeners();
    }
  }

  Future<void> _getUserData() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists) {
        userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _error = 'Failed to fetch user data';
      notifyListeners();
    }
  }

  Future<void> _fetchDominantColor(String imageUrl) async {
    final color = await _getDominantColor(imageUrl);
    _backgroundColor = color;
    notifyListeners();
  }

  Future<Color> _getDominantColor(String imageUrl) async {
    if (_dominantColors.containsKey(imageUrl)) {
      return _dominantColors[imageUrl]!;
    }
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(80, 80),
        maximumColorCount: 16,
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

  Future<void> captureAndSaveImage(String photoId, String photoUrl,
      GlobalKey cardKey, BuildContext context) async {
    bool hasPermission = true;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt < 33) {
        final status = await Permission.storage.request();
        hasPermission = status.isGranted;
        if (!hasPermission && status.isPermanentlyDenied) {
          _showPermissionDeniedSnackBar(context, 'Storage');
          return;
        } else if (!hasPermission) {
          _showSnackBar(context, 'Storage permission denied');
          return;
        }
      } else {
        final status = await Permission.photos.request();
        hasPermission = status.isGranted;
        if (!hasPermission && status.isPermanentlyDenied) {
          _showPermissionDeniedSnackBar(context, 'Photo access');
          return;
        } else if (!hasPermission) {
          _showSnackBar(context, 'Photo access permission denied');
          return;
        }
      }
    }

    if (!hasPermission) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        _showSnackBar(context, 'User data not found');
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
        _showSnackBar(context,
            'Subscription data is incomplete. Please contact support.');
        return;
      }

      // Allow download only if user has an active subscription or hasn't used their one-time free download
      if (hasActiveSubscription || !freeDownloadUsed) {
        try {
          _showSnackBar(context, 'Processing image...');

          final boundary = cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            _showSnackBar(context, 'Cannot capture image at this time');
            return;
          }

          const double pixelRatio = 5.0;
          const double a4Width = 3540.0;
          const double a4Height = 5424.0;

          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) throw Exception('Failed to capture image data');

          final codec =
              await ui.instantiateImageCodec(byteData.buffer.asUint8List());
          final frameInfo = await codec.getNextFrame();

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);

          canvas.drawImageRect(
            frameInfo.image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(0, 0, a4Width, a4Height),
            Paint()..filterQuality = FilterQuality.high,
          );

          final picture = recorder.endRecording();
          final a4Image =
              await picture.toImage(a4Width.toInt(), a4Height.toInt());
          final a4ByteData =
              await a4Image.toByteData(format: ui.ImageByteFormat.png);
          final a4PngBytes = a4ByteData!.buffer.asUint8List();

          await FlutterImageGallerySaver.saveImage(a4PngBytes);

          _showSnackBar(context, 'Image saved to gallery!', floating: true);

          // Update freeDownloadUsed only if this was a free download (no active subscription)
          if (!hasActiveSubscription) {
            await _firestore.collection('users').doc(userId).update({
              'freeDownloadUsed': true,
              'lastSubscriptionUpdate': Timestamp.now(),
            });
          }
        } catch (e) {
          print('Error saving image: $e');
          _showSnackBar(context, 'Error saving image: $e');
        }
      } else {
        _showSnackBar(context,
            'You have used your one-time free download. Please subscribe to download more images.');
        _showSubscriptionDialog(context);
      }
    } catch (e) {
      print('Error checking user subscription: $e');
      _showSnackBar(context, 'Error: $e');
    }
  }

  Future<void> shareImage(String photoId, String photoUrl, GlobalKey cardKey,
      BuildContext context) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        _showSnackBar(context, 'User data not found');
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
        _showSnackBar(context,
            'Subscription data is incomplete. Please contact support.');
        return;
      }

      if (hasActiveSubscription) {
        try {
          _showSnackBar(context, 'Preparing image for sharing...');

          final boundary = cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            _showSnackBar(context, 'Cannot capture image at this time');
            return;
          }

          const double pixelRatio = 5.0;
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) throw Exception('Failed to capture image data');

          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/share_image_$photoId.png');
          await tempFile.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles(
            [XFile(tempFile.path)],
          );

          await tempFile.delete();

          _showSnackBar(context, 'Image shared successfully!', floating: true);
        } catch (e) {
          print('Error sharing image: $e');
          _showSnackBar(context, 'Error sharing image: $e');
        }
      } else {
        await _showNotification(
          title: 'Subscription Required',
          body: 'Please subscribe to share images. Choose a plan to continue.',
        );
        _showSubscriptionDialog(context);
      }
    } catch (e) {
      print('Error checking user subscription: $e');
      _showSnackBar(context, 'Error: $e');
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

  void _showSubscriptionDialog(BuildContext context) {
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
              _buildPlanOption('Standard Plan', 300, 'month', context),
              _buildPlanOption('Premium Plan', 1000, 'year', context),
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

  Widget _buildPlanOption(
      String planName, int price, String duration, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(planName),
        subtitle: Text('\₹$price/$duration'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _redirectToWhatsApp(planName, price, duration, context),
      ),
    );
  }

  Future<void> _redirectToWhatsApp(
      String plan, int price, String duration, BuildContext context) async {
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
        if (!launched) {
          _showSnackBar(context,
              'Could not open WhatsApp. Please ensure WhatsApp is installed.');
        }
      } else {
        final fallbackUrl =
            'whatsapp://send?phone=$adminWhatsAppNumber&text=$encodedMessage';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        } else {
          _showSnackBar(
              context, 'WhatsApp is not installed or cannot be opened.');
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      _showSnackBar(context, 'Failed to open WhatsApp: $e');
    }

    Navigator.pop(context);
  }

  void _showSnackBar(BuildContext context, String message,
      {bool floating = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: floating ? SnackBarBehavior.floating : null,
      ),
    );
  }

  void _showPermissionDeniedSnackBar(
      BuildContext context, String permissionType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$permissionType permission is permanently denied. Please enable it in app settings.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }
}
