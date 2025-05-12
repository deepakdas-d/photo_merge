import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // For notifications
import 'dart:async'; // For timer functionality
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AdminSubscriptionPage extends StatefulWidget {
  const AdminSubscriptionPage({Key? key}) : super(key: key);

  @override
  State<AdminSubscriptionPage> createState() => _AdminSubscriptionPageState();
}

class _AdminSubscriptionPageState extends State<AdminSubscriptionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _adminId;

  // Filter options
  String _filterOption = 'All';
  final List<String> _filterOptions = [
    'All',
    'Active',
    'Expired',
    'Never Subscribed'
  ];

  // For category-based plans
  final Map<String, List<SubscriptionPlan>> _categoryPlans = {};
  List<String> _categories = [];
  bool _isLoading = true;

  // For subscription alerts tracking
  final Map<String, StreamSubscription<DocumentSnapshot>>
      _subscriptionListeners = {};

  @override
  void initState() {
    super.initState();

    _loadCategories();
    _initializeNotifications();
  }

  @override
  void dispose() {
    // Cancel all subscription listeners when the page is disposed
    for (var subscription in _subscriptionListeners.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // No default icon
      [
        NotificationChannel(
          channelKey: 'subscription_channel',
          channelName: 'Subscription Notifications',
          channelDescription:
              'Notifications related to subscription status changes',
          importance: NotificationImportance.High,
          enableVibration: true,
        ),
      ],
    );
  }

  Future<void> _loadCategories() async {
    try {
      // Reset the loading state
      setState(() {
        _isLoading = true;
      });

      // First, load all categories
      final categorySnapshot = await _firestore.collection('categories').get();
      List<String> categories = [];

      for (var doc in categorySnapshot.docs) {
        final categoryName = doc['name'] as String;
        categories.add(categoryName);

        // For each category, define subscription plans
        _categoryPlans[categoryName] = [
          SubscriptionPlan(
            name: 'Standard Plan',
            duration: const Duration(days: 30),
            price: 300,
            features: [
              'Download watermark-free images',
              'Access to all subcategories'
            ],
            categorySpecific: true,
          ),
          SubscriptionPlan(
            name: 'Premium Plan',
            duration: const Duration(days: 365),
            price: 1000,
            features: [
              'Download watermark-free images',
              'Access to all subcategories',
              'Priority customer support',
              'Early access to new features'
            ],
            categorySpecific: true,
          ),
        ];
      }

      // Add universal plan options
      _categoryPlans['Universal'] = [
        SubscriptionPlan(
          name: 'Universal Standard',
          duration: const Duration(days: 30),
          price: 500,
          features: [
            'Access to all categories',
            'Download watermark-free images'
          ],
          categorySpecific: false,
        ),
        SubscriptionPlan(
          name: 'Universal Premium',
          duration: const Duration(days: 365),
          price: 1800,
          features: [
            'Access to all categories',
            'Download watermark-free images',
            'Priority customer support',
            'Early access to new features'
          ],
          categorySpecific: false,
        ),
      ];

      // Add Universal to the list of categories
      categories.add('Universal');

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _setupSubscriptionAlert(String userId, String email) async {
    // Cancel any existing listener for this user
    if (_subscriptionListeners.containsKey(userId)) {
      await _subscriptionListeners[userId]?.cancel();
    }

    // Create a new listener
    final subscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userDoc) async {
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final bool isSubscribed = userData['isSubscribed'] ?? false;
      final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

      if (isSubscribed && subscriptionExpiry != null) {
        final expiryDate = subscriptionExpiry.toDate();
        final now = DateTime.now();

        // Calculate days left
        final difference = expiryDate.difference(now).inDays;

        // Check if subscription is expiring in 7 days or less
        if (difference <= 7 && difference >= 0) {
          // Send notification to user
          await _sendExpiryReminderToUser(userId, email, difference,
              userData['subscriptionPlan'] ?? 'your plan');

          // Send notification to admin
          await _showNotification(
            title: 'Subscription Expiring Soon',
            body: 'User $email subscription expires in $difference days',
          );
        }
        // Check if subscription just expired
        else if (difference < 0 && difference > -2) {
          // Only alert on first day of expiry
          // Send expiry notification to user
          await _sendExpiryNotificationToUser(
              userId, email, userData['subscriptionPlan'] ?? 'your plan');

          // Update subscription status if it just expired
          if (isSubscribed) {
            await _firestore.collection('users').doc(userId).update({
              'isSubscribed': false,
              'lastSubscriptionUpdate': Timestamp.now(),
            });

            // Notify admin
            await _showNotification(
              title: 'Subscription Expired',
              body: 'User $email subscription has expired',
            );
          }
        }
      }
    });

    // Store the subscription listener
    _subscriptionListeners[userId] = subscription;
  }

  Future<void> _sendExpiryReminderToUser(
      String userId, String email, int daysLeft, String planName) async {
    try {
      // Create a reminder notification in user's notifications collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Subscription Expiring Soon',
        'message':
            'Your $planName subscription will expire in $daysLeft days. Renew now to continue downloading images.',
        'timestamp': Timestamp.now(),
        'read': false,
        'type': 'subscription_reminder',
      });
    } catch (e) {
      print('Error sending expiry reminder to user: $e');
    }
  }

  Future<void> _sendExpiryNotificationToUser(
      String userId, String email, String planName) async {
    try {
      // Create an expiry notification in user's notifications collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Subscription Expired',
        'message':
            'Your $planName subscription has expired. Renew now to continue downloading images.',
        'timestamp': Timestamp.now(),
        'read': false,
        'type': 'subscription_expired',
      });
    } catch (e) {
      print('Error sending expiry notification to user: $e');
    }
  }

  Future<void> _showNotification(
      {required String title, required String body}) async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Request POST_NOTIFICATIONS permission for Android 13+
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
        channelKey: 'subscription_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  void _approveSubscription(BuildContext context, String userId, String email) {
    String selectedCategory = _categories.isNotEmpty ? _categories[0] : '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Approve Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: $email'),
                const SizedBox(height: 10),
                const Text('Select Category:'),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Select Plan:'),
                ..._categoryPlans[selectedCategory]?.map((plan) {
                      final durationText = plan.duration.inDays >= 365
                          ? '${plan.duration.inDays ~/ 365} year${plan.duration.inDays >= 730 ? 's' : ''}'
                          : '${plan.duration.inDays} days';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(plan.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${plan.price} - $durationText'),
                              const SizedBox(height: 4),
                              ...plan.features
                                  .map((feature) => Text('• $feature',
                                      style: const TextStyle(fontSize: 12)))
                                  .toList(),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _updateSubscription(
                                userId, email, selectedCategory, plan),
                            child: const Text('Select'),
                          ),
                        ),
                      );
                    }).toList() ??
                    [],
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
      ),
    );
  }

  Future<void> _updateSubscription(String userId, String email, String category,
      SubscriptionPlan plan) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(plan.duration);

      // Update user's subscription information
      await _firestore.collection('users').doc(userId).update({
        'isSubscribed': true,
        'subscriptionPlan': plan.name,
        'subscriptionCategory': plan.categorySpecific ? category : 'Universal',
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionPrice': plan.price,
        'subscriptionFeatures': plan.features,
        'lastSubscriptionUpdate': Timestamp.now(),
      });

      // Create transaction record
      await _firestore.collection('subscription_transactions').add({
        'userId': userId,
        'userEmail': email,
        'plan': plan.name,
        'category': plan.categorySpecific ? category : 'Universal',
        'price': plan.price,
        'startDate': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'approvedBy': _adminId,
        'approvedAt': Timestamp.now(),
        'status': 'active',
      });

      // Add notification for the user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Subscription Approved',
        'message':
            'Your ${plan.name} subscription has been approved! You can now download images until ${DateFormat('dd MMM yyyy').format(expiryDate)}.',
        'timestamp': Timestamp.now(),
        'read': false,
        'type': 'subscription_approved',
      });

      // Set up automatic subscription alert
      await _setupSubscriptionAlert(userId, email);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription approved for $email')),
        );
      }
    } catch (e) {
      print('Error updating subscription: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating subscription: $e')),
        );
      }
    }
  }

  Future<void> _revokeSubscription(
      BuildContext context, String userId, String email) async {
    try {
      // Get current subscription details for record keeping
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        final currentPlan = userData['subscriptionPlan'];
        final currentCategory = userData['subscriptionCategory'];

        // Create transaction record for revocation
        await _firestore.collection('subscription_transactions').add({
          'userId': userId,
          'userEmail': email,
          'plan': currentPlan ?? 'Unknown',
          'category': currentCategory ?? 'Unknown',
          'revokedAt': Timestamp.now(),
          'revokedBy': _adminId,
          'status': 'revoked',
          'previousExpiryDate': userData['subscriptionExpiry'],
        });

        // Update user record
        await _firestore.collection('users').doc(userId).update({
          'isSubscribed': false,
          'subscriptionPlan': '',
          'subscriptionCategory': '',
          'subscriptionExpiry': null,
          'lastSubscriptionUpdate': Timestamp.now(),
        });

        // Add notification for the user
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'title': 'Subscription Revoked',
          'message':
              'Your subscription has been revoked. Please contact admin for details.',
          'timestamp': Timestamp.now(),
          'read': false,
          'type': 'subscription_revoked',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subscription revoked for $email')),
          );
        }
      }
    } catch (e) {
      print('Error revoking subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error revoking subscription: $e')),
        );
      }
    }
  }

  Future<void> _extendSubscription(BuildContext context, String userId,
      String email, Timestamp? currentExpiry) async {
    final TextEditingController daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User: $email'),
            const SizedBox(height: 8),
            if (currentExpiry != null)
              Text(
                  'Current expiry: ${DateFormat('dd MMM yyyy').format(currentExpiry.toDate())}'),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              decoration: const InputDecoration(
                labelText: 'Enter days to extend',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final days = int.tryParse(daysController.text);
                if (days == null || days <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid number of days')),
                  );
                  return;
                }

                final userDoc =
                    await _firestore.collection('users').doc(userId).get();
                if (!userDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not found')),
                  );
                  return;
                }

                final userData = userDoc.data()!;
                final Timestamp? oldExpiry = userData['subscriptionExpiry'];
                final DateTime baseDate = oldExpiry?.toDate() ?? DateTime.now();
                final DateTime newExpiry = baseDate.add(Duration(days: days));

                await _firestore.collection('users').doc(userId).update({
                  'isSubscribed': true,
                  'subscriptionExpiry': Timestamp.fromDate(newExpiry),
                  'lastSubscriptionUpdate': Timestamp.now(),
                });

                // Add transaction record
                await _firestore.collection('subscription_transactions').add({
                  'userId': userId,
                  'userEmail': email,
                  'plan': userData['subscriptionPlan'] ?? 'Unknown',
                  'category': userData['subscriptionCategory'] ?? 'Unknown',
                  'extendedAt': Timestamp.now(),
                  'extendedBy': _adminId,
                  'extendedDays': days,
                  'previousExpiryDate': oldExpiry,
                  'newExpiryDate': Timestamp.fromDate(newExpiry),
                  'status': 'extended',
                });

                // Add notification for the user
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('notifications')
                    .add({
                  'title': 'Subscription Extended',
                  'message':
                      'Your subscription has been extended by $days days. New expiry date: ${DateFormat('dd MMM yyyy').format(newExpiry)}.',
                  'timestamp': Timestamp.now(),
                  'read': false,
                  'type': 'subscription_extended',
                });

                // Set up automatic subscription alert
                await _setupSubscriptionAlert(userId, email);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Subscription extended by $days days')),
                );
              } catch (e) {
                print('Error extending subscription: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error extending subscription: $e')),
                );
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  Query<Map<String, dynamic>> _getFilteredQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    switch (_filterOption) {
      case 'Active':
        query = query.where('isSubscribed', isEqualTo: true);
        break;
      case 'Expired':
        final now = Timestamp.now();
        query = query
            .where('isSubscribed', isEqualTo: false)
            .where('subscriptionExpiry', isLessThan: now);
        break;
      case 'Never Subscribed':
        query = query.where('subscriptionPlan', isEqualTo: '');
        break;
      case 'All':
      default:
        // No filter applied
        break;
    }

    return query;
  }

  String _getSubscriptionStatus(Map<String, dynamic> userData) {
    final bool isSubscribed = userData['isSubscribed'] ?? false;
    final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

    if (!isSubscribed) {
      final bool freeDownloadUsed = userData['freeDownloadUsed'] ?? false;
      return freeDownloadUsed ? 'Free download used' : 'Never subscribed';
    }

    if (subscriptionExpiry == null) {
      return 'Active (no expiry)';
    }

    final now = DateTime.now();
    final expiryDate = subscriptionExpiry.toDate();

    if (expiryDate.isBefore(now)) {
      return 'Expired';
    }

    final difference = expiryDate.difference(now).inDays;
    if (difference <= 7) {
      return 'Active (expires in $difference days)';
    }

    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Subscriptions'),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Manage Subscriptions',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterOption,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterOption = value;
                        });
                      }
                    },
                    items: _filterOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final email = userData['email'] ?? 'No email';
                    final firstName = userData['firstName'] ?? '';
                    final lastName = userData['lastName'] ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final isSubscribed = userData['isSubscribed'] ?? false;
                    final subscriptionPlan =
                        userData['subscriptionPlan'] ?? 'None';
                    final subscriptionCategory =
                        userData['subscriptionCategory'] ?? 'None';
                    final subscriptionExpiry =
                        userData['subscriptionExpiry'] as Timestamp?;
                    final status = _getSubscriptionStatus(userData);

                    // Setup subscription alert listener for this user
                    _setupSubscriptionAlert(userId, email);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isSubscribed ? Colors.green : Colors.grey,
                          child: Icon(
                            isSubscribed ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          fullName.isNotEmpty ? fullName : email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Status: $status'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: $email'),
                                const SizedBox(height: 4),
                                Text('Plan: $subscriptionPlan'),
                                const SizedBox(height: 4),
                                Text('Category: $subscriptionCategory'),
                                const SizedBox(height: 4),
                                if (subscriptionExpiry != null)
                                  Text(
                                      'Expiry: ${DateFormat('dd MMM yyyy').format(subscriptionExpiry.toDate())}'),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _approveSubscription(
                                          context, userId, email),
                                      icon: const Icon(Icons.add),
                                      label: const Text('New Plan'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                    if (isSubscribed)
                                      ElevatedButton.icon(
                                        onPressed: () => _extendSubscription(
                                            context,
                                            userId,
                                            email,
                                            subscriptionExpiry),
                                        icon: const Icon(Icons.extension),
                                        label: const Text('Extend'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),
                                    if (isSubscribed)
                                      ElevatedButton.icon(
                                        onPressed: () => _revokeSubscription(
                                            context, userId, email),
                                        icon: const Icon(Icons.remove_circle),
                                        label: const Text('Revoke'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// Subscription plan model
class SubscriptionPlan {
  final String name;
  final Duration duration;
  final int price;
  final List<String> features;
  final bool categorySpecific;

  SubscriptionPlan({
    required this.name,
    required this.duration,
    required this.price,
    required this.features,
    required this.categorySpecific,
  });
}
