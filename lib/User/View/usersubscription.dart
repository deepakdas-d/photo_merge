import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class UserSubscriptionPage extends StatefulWidget {
  const UserSubscriptionPage({Key? key}) : super(key: key);

  @override
  _UserSubscriptionPageState createState() => _UserSubscriptionPageState();
}

class _UserSubscriptionPageState extends State<UserSubscriptionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  String? _error;
  Timer? _countdownTimer;
  final ValueNotifier<Duration?> _timeUntilExpiry = ValueNotifier(null);
  Map<String, dynamic>? _lastSnapshotData;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _fetchUserData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timeUntilExpiry.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No user logged in';
      });
      return;
    }
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          _isLoading = false;
          _error = null;
        });
        _updateCountdown();
      } else {
        setState(() {
          _isLoading = false;
          _error = 'User data not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error fetching subscription';
      });
      _logError('fetchUserData', e.toString());
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (userData == null) return;
    final Timestamp? subscriptionExpiry = userData?['subscriptionExpiry'];
    if (subscriptionExpiry == null) {
      _timeUntilExpiry.value = null;
      return;
    }
    final expiryDate = subscriptionExpiry.toDate();
    final now = DateTime.now();
    if (expiryDate.isAfter(now)) {
      final newDuration = expiryDate.difference(now);
      if (_timeUntilExpiry.value == null ||
          newDuration.inMinutes != _timeUntilExpiry.value!.inMinutes) {
        _timeUntilExpiry.value = newDuration;
      }
    } else {
      _firestore.collection('users').doc(userId).update({
        'isSubscribed': false,
      }).catchError((e) {
        _logError('updateSubscriptionStatus', e.toString());
      });
      setState(() {
        _timeUntilExpiry.value = null;
        userData?['isSubscribed'] = false;
      });
    }
  }

  Future<void> _logError(String function, String error) async {
    try {
      await _firestore.collection('logs').add({
        'function': function,
        'error': error,
        'userId': userId ?? 'unknown',
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  Future<void> _redirectToWhatsApp(
      String plan, int price, String duration) async {
    const adminWhatsAppNumber = '+919567725398';
    final message =
        'Hello, I want to ${userData?['isSubscribed'] == true ? 'renew' : 'subscribe to'} the $plan (\₹$price/$duration) for the PhotoMerge app.';
    final encodedMessage = Uri.encodeComponent(message);

    final whatsappUrl =
        'https://wa.me/$adminWhatsAppNumber?text=$encodedMessage';
    final uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not open WhatsApp. Please ensure WhatsApp is installed.')),
          );
        }
      } else {
        final fallbackUrl =
            'whatsapp://send?phone=$adminWhatsAppNumber&text=$encodedMessage';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('WhatsApp is not installed or cannot be opened.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open WhatsApp')),
        );
      }
      _logError('redirectToWhatsApp', e.toString());
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Choose a Subscription Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select a plan to continue downloading images.'),
              const SizedBox(height: 12),
              _buildPlanOption('Standard Plan', 300, 'month'),
              _buildPlanOption('Premium Plan', 1000, 'year'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String planName, int price, String duration) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title:
            Text(planName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('\₹$price/$duration'),
        trailing: const Icon(Icons.arrow_forward, color: Color(0xFF4CAF50)),
        onTap: () {
          Navigator.pop(context);
          _redirectToWhatsApp(planName, price, duration);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Subscription',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchUserData();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: _error != null
                    ? _buildErrorCard()
                    : StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF4CAF50)));
                          }
                          if (snapshot.hasError) {
                            _logError(
                                'streamBuilder', snapshot.error.toString());
                            return _buildErrorCard(error: 'Error loading data');
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildSubscriptionCard(isSubscribed: false);
                          }
                          final newData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (newData != null && _isDataChanged(newData)) {
                            userData = newData;
                            _lastSnapshotData = Map.from(newData);
                            _updateCountdown();
                          }
                          return _buildSubscriptionCard();
                        },
                      ),
              ),
            ),
    );
  }

  bool _isDataChanged(Map<String, dynamic> newData) {
    if (_lastSnapshotData == null) return true;
    return newData['isSubscribed'] != _lastSnapshotData!['isSubscribed'] ||
        newData['subscriptionPlan'] != _lastSnapshotData!['subscriptionPlan'] ||
        (newData['subscriptionExpiry'] as Timestamp?)?.seconds !=
            (_lastSnapshotData!['subscriptionExpiry'] as Timestamp?)?.seconds;
  }

  Widget _buildErrorCard({String? error}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF4CAF50)),
            const SizedBox(height: 12),
            Text(
              error ?? _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchUserData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({bool isSubscribed = true}) {
    final bool subscriptionActive =
        isSubscribed && (userData?['isSubscribed'] ?? false);
    final String subscriptionPlan = userData?['subscriptionPlan'] ?? 'None';
    final Timestamp? subscriptionExpiry = userData?['subscriptionExpiry'];

    bool isNearExpiry = false;
    bool isExpired = true;
    String expiryText = 'Not available';

    if (subscriptionActive && subscriptionExpiry != null) {
      final expiryDate = subscriptionExpiry.toDate();
      isExpired = !expiryDate.isAfter(DateTime.now());
      isNearExpiry = !isExpired &&
          _timeUntilExpiry.value != null &&
          _timeUntilExpiry.value!.inDays <= 3;
      expiryText = isExpired
          ? 'Expired on: ${DateFormat.yMMMd().format(expiryDate)}'
          : 'Expires on: ${DateFormat.yMMMd().format(expiryDate)}';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isExpired
                  ? Icons.warning
                  : (subscriptionActive
                      ? Icons.check_circle
                      : Icons.info_outline),
              size: 48,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            Text(
              isExpired
                  ? 'Expired Subscription'
                  : (subscriptionActive
                      ? 'Active Subscription'
                      : 'No Active Subscription'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Plan: $subscriptionPlan',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              expiryText,
              style: const TextStyle(fontSize: 14),
            ),
            if (subscriptionActive)
              ValueListenableBuilder<Duration?>(
                valueListenable: _timeUntilExpiry,
                builder: (context, duration, child) {
                  if (duration == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Time Remaining: ${_formatDuration(duration)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showSubscriptionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isExpired
                    ? 'Renew Now'
                    : (subscriptionActive ? 'Change Plan' : 'Subscribe Now'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    return '${days}d ${hours}h ${minutes}m';
  }
}
