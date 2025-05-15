import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/Admin/image_/a_listimages.dart';
import 'package:photomerge/Admin/image_/add_posters.dart';
import 'package:photomerge/Admin/categories/categoreymanagment.dart';

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
    // {
    //   'icon': Icons.person_add,
    //   'title': 'Add Admin',
    //   'subtitle': 'Create a new admin account.',
    //   'onTap': (BuildContext context) =>
    //       Navigator.pushNamed(context, '/createadmin')
    // },
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
      'icon': Icons.view_carousel,
      'title': 'Carousel',
      'subtitle': 'Manage carousel items.',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/carousel')
    },
    {
      'icon': Icons.video_collection_sharp,
      'title': 'Video Carousel',
      'subtitle': 'Manage video carousel items.',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/vediourl')
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
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> logout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isLoggedIn': false,
          'deviceId': '',
        });
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await logout(); // This handles Firestore update and sign out
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exit App',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 20),
            ),
            content: Text('Do you really want to close the app?'),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No', style: TextStyle(color: Colors.red[600])),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes', style: TextStyle(color: Colors.red[600])),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(200.0), // Adjust height as needed
          child: ClipPath(
            clipper: CurvedBottomClipper(),
            child: Container(
              color: Colors.red[600],
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchController.clear();
                              _filteredActions = _allActions;
                            }
                          });
                        },
                        icon: Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _isSearching
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 45.0, left: 20),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: _filterSearch,
                                  decoration: InputDecoration(
                                    hintText: 'Search actions...',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 80.0),
                                child: Text(
                                  'Admin Dashboard',
                                  style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 90.0),
                      child: IconButton(
                        icon: Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Sign Out',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  'Confirm Logout',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content:
                                    Text('Are you sure you want to log out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.red[600]),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _signOut();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Logout'),
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
              ),
            ),
          ),
        ),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.red[200],
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.red[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(16.0),
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Welcome, ${_adminEmail ?? 'Admin'}!',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Manage Your Gallery:',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  _filteredActions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No matching actions found.',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.0,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          children: _filteredActions.map((action) {
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
                          }).toList(),
                        ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            SubtitleWithAnimation(
              text: subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

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
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start slightly below
      end: const Offset(0, 0), // End at original position
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
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
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: Colors.black,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    final p0 = size.height * 0.75;
    path.lineTo(0.0, p0);

    final controlPoint = Offset(size.width * 0.5, size.height);
    final endPoint = Offset(size.width + 50, size.height / 3);
    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
