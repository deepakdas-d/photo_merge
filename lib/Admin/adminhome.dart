// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/Admin/a_listimages.dart';
import 'package:photomerge/Admin/add_posters.dart';
import 'package:photomerge/Admin/categoreymanagment.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _adminEmail;

  final List<Map<String, dynamic>> _allActions = [
    {
      'icon': Icons.category,
      'title': 'Manage Categories',
      'subtitle': 'Add, edit, or delete categories and subcategories.',
      'onTap': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoryManagementPage()),
          )
    },
    {
      'icon': Icons.add_photo_alternate,
      'title': 'Add Images',
      'subtitle': 'Upload new images to the gallery.',
      'onTap': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddImagePage()),
          )
    },
    {
      'icon': Icons.image,
      'title': 'List Images',
      'subtitle': 'View and manage all uploaded images.',
      'onTap': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListImagesPage()),
          )
    },
    {
      'icon': Icons.person_add,
      'title': 'Add Admin',
      'subtitle': 'Create a new admin account.',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/createadmin')
    },
    {
      'icon': Icons.person_add,
      'title': 'List Users',
      'subtitle': 'List all users.',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/listusers')
    },
    {
      'icon': Icons.money_rounded,
      'title': 'Subscriptions',
      'subtitle': 'Manage subscriptions.',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/submanage')
    },
    {
      'icon': Icons.money_rounded,
      'title': 'Carousel',
      'subtitle': 'Manage carousel items.',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/carousel')
    },
  ];

  List<Map<String, dynamic>> _filteredActions = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _filteredActions = _allActions;
  }

  Future<void> _loadAdminData() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      setState(() {
        _adminEmail = currentUser.email;
      });
    } else {
      // If no user is signed in, redirect to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _signOut() async {
    try {
      await _firebaseAuth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _filterSearch(String query) {
    final filtered = _allActions.where((action) {
      final title = action['title']!.toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredActions = filtered;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exit App',
              style: GoogleFonts.oswald(fontSize: 20),
            ),
            content: Text('Do you really want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        );
        return shouldExit ?? false; // default to false if null
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredActions = _allActions;
                }
              });
            },
            icon: Icon(Icons.search),
            color: Colors.white,
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _filterSearch,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white),
                )
              : Text(
                  'Admin Dashboard',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          backgroundColor: Colors.green,
          centerTitle: true,
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Sign Out',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.green[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Confirm Logout',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(color: Colors.black),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _signOut();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(vertical: 5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Welcome, ${_adminEmail ?? 'Admin'}!',
                    style: GoogleFonts.oswald(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Manage your photo gallery:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _filteredActions.isEmpty
                      ? Center(
                          child: Text(
                            'No matching actions found.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 1.10,
                          ),
                          itemCount: _filteredActions.length,
                          itemBuilder: (context, index) {
                            final action = _filteredActions[index];
                            return _buildActionTile(
                              context,
                              icon: action['icon'] as IconData,
                              title: action['title'] as String,
                              subtitle: action['subtitle'] as String,
                              onTap: () {
                                final Function(BuildContext) onTapFn =
                                    action['onTap'] as Function(BuildContext);
                                onTapFn(context);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated _buildActionTile method with continuous subtitle animation
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              // Continuous subtitle animation
              SubtitleWithAnimation(
                text: subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom widget for continuous subtitle animation
class SubtitleWithAnimation extends StatefulWidget {
  final String text;

  const SubtitleWithAnimation({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  _SubtitleWithAnimationState createState() => _SubtitleWithAnimationState();
}

class _SubtitleWithAnimationState extends State<SubtitleWithAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Create an animation controller that repeats forever
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create a subtle sliding animation
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(0.0, 0.0),
          end: Offset(-0.025, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(-0.025, 0.0),
          end: Offset(0.025, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(0.025, 0.0),
          end: Offset(0.0, 0.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Start the animation and make it repeat
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
