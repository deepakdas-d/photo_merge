import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class Mycategory extends StatefulWidget {
  final String categoryFilter; // Required category filter

  const Mycategory({Key? key, required this.categoryFilter}) : super(key: key);

  @override
  State<Mycategory> createState() => _MycategoryState();
}

class _MycategoryState extends State<Mycategory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData = {}; // Initialize as empty map to avoid null
  String? _selectedSubcategory; // Track selected subcategory (null for "All")
  List<String> _subcategories = [
    'All'
  ]; // List of subcategories including "All"

  // Cached maps for performance
  final Map<String, GlobalKey> _photoKeys = {};
  final Map<String, Color> _dominantColors = {};

  // Constants
  static const String adminImagesCollection = 'admin_images';
  static const String imagesSubcollection = 'images';
  static const double fadeHeight = 100.0;
  static const int maxColorCount = 10;
  static const double pixelRatio = 3.0;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _fetchSubcategories();
    _checkSubscriptionUpdate();
    _checkSubscriptionExpiryReminder();
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

  Future<void> _getUserData() async {
    if (userId == null) {
      print('No user is authenticated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view user details')),
        );
        setState(() => userData = {}); // Ensure UI can proceed
      }
      return;
    }

    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (!doc.exists) {
        print('User document does not exist for userId: $userId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found')),
          );
          setState(() => userData = {}); // Allow UI to proceed
        }
        return;
      }

      final data = doc.data();
      if (data == null || data.isEmpty) {
        print('User document is empty for userId: $userId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile data is empty')),
          );
          setState(() => userData = {}); // Allow UI to proceed
        }
        return;
      }

      if (mounted) {
        setState(() {
          userData = data;
          print('User data fetched: $userData');
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
        setState(() => userData = {}); // Allow UI to proceed
      }
    }
  }

  Future<void> _fetchSubcategories() async {
    try {
      print(
          'Fetching subcategories for category: ${widget.categoryFilter}, userId: $userId');
      final snapshot = await _firestore
          .collection('categories')
          .where('createdBy', isEqualTo: userId)
          .get();

      print('Found ${snapshot.docs.length} category documents');
      List<String> subcategories = [];
      for (var doc in snapshot.docs) {
        final categoryName = doc['name']?.toString().toLowerCase();
        print('Checking category: $categoryName');
        if (categoryName == widget.categoryFilter.toLowerCase()) {
          print('Match found for category: ${doc['name']}');
          subcategories = List<String>.from(doc['subcategories'] ?? []);
          print('Subcategories found: $subcategories');
          break;
        }
      }

      if (subcategories.isNotEmpty) {
        if (mounted) {
          setState(() {
            _subcategories = ['All', ...subcategories];
            print('Updated subcategories: $_subcategories');
          });
        }
        return;
      }

      // Fallback: Query the images collection group
      print(
          'No subcategories found in categories collection, falling back to images');
      final imageSnapshot = await _firestore
          .collectionGroup(imagesSubcollection)
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
          print('Updated subcategories from images: $_subcategories');
        });
      }

      // Update categories collection if a matching document exists
      for (var doc in snapshot.docs) {
        if (doc['name'].toString().toLowerCase() ==
            widget.categoryFilter.toLowerCase()) {
          await _firestore.collection('categories').doc(doc.id).update({
            'subcategories': subcategoriesSet.toList()..remove('All'),
          });
          print(
              'Updated categories document with subcategories: ${subcategoriesSet.toList()..remove('All')}');
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

  Future<void> _checkSubscriptionUpdate() async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final lastUpdate = userDoc['lastSubscriptionUpdate'] as Timestamp?;
      final notificationShown = userDoc['notificationShown'] ?? false;
      if (lastUpdate != null &&
          lastUpdate
              .toDate()
              .isAfter(DateTime.now().subtract(const Duration(minutes: 5))) &&
          !notificationShown &&
          mounted) {
        await _showNotification(
          title: 'Subscription Approved!',
          body:
              'Your subscription has been approved. You can now download images.',
        );
        await _firestore.collection('users').doc(userId).update({
          'notificationShown': true,
        });
      }
    } catch (e) {
      print('Error checking subscription update: $e');
    }
  }

  Future<void> _checkSubscriptionExpiryReminder() async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final expiry = userDoc['subscriptionExpiry'] as Timestamp?;
      final isSubscribed = userDoc['isSubscribed'] ?? false;
      if (expiry != null && isSubscribed) {
        final daysUntilExpiry =
            expiry.toDate().difference(DateTime.now()).inDays;
        if (daysUntilExpiry <= 3 && daysUntilExpiry > 0 && mounted) {
          await _showNotification(
            title: 'Subscription Expiring Soon',
            body:
                'Your subscription expires in $daysUntilExpiry days. Renew now to continue downloading images.',
          );
        }
      }
    } catch (e) {
      print('Error checking subscription expiry reminder: $e');
    }
  }

  Future<Color> _getDominantColor(String imageUrl) async {
    if (_dominantColors.containsKey(imageUrl)) {
      return _dominantColors[imageUrl]!;
    }
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: maxColorCount,
      );
      final dominantColor =
          paletteGenerator.dominantColor?.color ?? Colors.white;
      _dominantColors[imageUrl] = dominantColor;
      return dominantColor;
    } catch (e) {
      print('Error getting dominant color for $imageUrl: $e');
      return Colors.white;
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
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          final pngBytes = byteData!.buffer.asUint8List();

          try {
            await FlutterImageGallerySaver.saveImage(pngBytes);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image saved to gallery!')),
            );
          } catch (e) {
            print('Error saving image to gallery: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save image')),
            );
          }

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

  Stream<List<QueryDocumentSnapshot>> _getImagesStream() {
    var query = _firestore
        .collectionGroup(imagesSubcollection)
        .where('category', isEqualTo: widget.categoryFilter);

    if (_selectedSubcategory != null && _selectedSubcategory != 'All') {
      query = query.where('subcategory', isEqualTo: _selectedSubcategory);
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  Widget _buildPhotoCard(
      String photoId, String photoUrl, Color backgroundColor) {
    if (!_photoKeys.containsKey(photoId)) {
      _photoKeys[photoId] = GlobalKey();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          RepaintBoundary(
            key: _photoKeys[photoId],
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 5 / 6,
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) {
                          print('Image load error for $url: $error');
                          return const Icon(Icons.error);
                        },
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: WatermarkPainter()),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: fadeHeight * 2.0,
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
                              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        backgroundColor,
                        backgroundColor,
                        backgroundColor.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: userData?['userImage'] != null
                            ? NetworkImage(userData!['userImage'])
                            : null,
                        child: userData?['userImage'] == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData?['firstName'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                userData?['designation'] ?? 'No designation',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.email,
                                      size: 16, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      userData?['email'] ?? 'No email',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (userData?['companyLogo'] != null &&
                          userData!['companyLogo'].isNotEmpty)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.network(
                            userData!['companyLogo'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Logo load error: $error');
                              return const Icon(Icons.error);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download Merged Image'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40)),
              onPressed: () => _captureAndSaveImage(photoId, photoUrl),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryFilter} Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _getUserData();
              _fetchSubcategories();
              _checkSubscriptionExpiryReminder();
            },
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
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getImagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_album_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedSubcategory == null
                              ? 'No photos found in the "${widget.categoryFilter}" category'
                              : 'No photos found in the "${widget.categoryFilter} - $_selectedSubcategory" category',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final photo =
                        snapshot.data![index].data() as Map<String, dynamic>;
                    final photoId = snapshot.data![index].id;
                    final photoUrl = photo['image_url'] ?? '';
                    return FutureBuilder<Color>(
                      future: _getDominantColor(photoUrl),
                      builder: (context, colorSnapshot) {
                        if (!colorSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _buildPhotoCard(
                            photoId, photoUrl, colorSnapshot.data!);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Generated by PhotoMerge',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 30,
          fontWeight: FontWeight.bold,
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
