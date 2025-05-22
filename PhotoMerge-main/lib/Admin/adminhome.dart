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
      'subtitle': 'Add, edit, or delete categories',
      'onTap': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoryManagementPage()),
          )
    },
    {
      'icon': Icons.add_photo_alternate,
      'title': 'Add Images',
      'subtitle': 'Upload new images',
      'onTap': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddImagePage()),
          )
    },
    {
      'icon': Icons.image,
      'title': 'List Images',
      'subtitle': 'View all images',
      'onTap': (BuildContext context) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListImagesPage()),
          )
    },
    {
      'icon': Icons.person_add,
      'title': 'Users',
      'subtitle': 'Manage users',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/listusers')
    },
    {
      'icon': Icons.money_rounded,
      'title': 'Subscriptions',
      'subtitle': 'Subscription plans',
      'onTap': (BuildContext context) =>
          Navigator.pushNamed(context, '/submanage')
    },
    {
      'icon': Icons.view_carousel,
      'title': 'Carousel',
      'subtitle': 'Manage slideshows',
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
    // {
    //   'icon': Icons.new_label,
    //   'title': 'Admin Home',
    //   'subtitle': 'Create Admin.',
    //   'onTap': (BuildContext context) =>
    //       Navigator.pushNamed(context, '/createadmin')
    // },
  ];

  List<Map<String, dynamic>> _filteredActions = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _filteredActions = _allActions;
  }

  void _refreshUserList() {
    setState(() {});
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
      await logout();
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
              borderRadius: BorderRadius.circular(16),
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
        backgroundColor: Color(0xFFF5F5F7),
        body: Stack(
          children: [
            // Top curved container
            Container(
              height: MediaQuery.of(context).size.height * 0.40,
              decoration: BoxDecoration(
                color: Color(0xFF00B6B0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // App bar with profile and search
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: GoogleFonts.oswald(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 35),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          radius: 20,
                          child: IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      'Confirm Logout',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                        'Are you sure you want to log out?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(
                                          'Cancel',
                                          style:
                                              TextStyle(color: Colors.red[600]),
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
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
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

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterSearch,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),

                  // Admin info card
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [],
                      ),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      //  'Welcome, ${_adminEmail ?? 'Admin'}!',
                                      "ADMIN DASHBOARD",
                                      style: GoogleFonts.poppins(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main content grid
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.7), // darker shadow
                            spreadRadius: 8, // larger spread
                            blurRadius: 30, // softer and wider
                            offset: Offset(0, 10), // more vertical distance
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              physics: BouncingScrollPhysics(),
                              children: _filteredActions.map((action) {
                                return _buildActionCard(
                                  context,
                                  icon: action['icon'] as IconData,
                                  title: action['title'] as String,
                                  subtitle: action['subtitle'] as String,
                                  onTap: () {
                                    final Function(BuildContext) onTapFn =
                                        action['onTap'] as Function(
                                            BuildContext);
                                    onTapFn(context);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom navigation
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: InkWell(
                              onTap: _refreshUserList,
                              borderRadius: BorderRadius.circular(
                                  100), // to match the circle
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.sync_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(title),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 24,
                color: _getIconColor(title),
              ),
            ),
            SizedBox(height: 10),
            Text(
              title.split(' ')[0],
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for icon colors to match the design
  Color _getIconBackgroundColor(String title) {
    if (title.contains('Manage Categories')) return Colors.amber[100]!;
    if (title.contains('Add Images')) return Colors.yellow[100]!;
    if (title.contains('List')) return Colors.blue[100]!;
    if (title.contains('Users')) return Colors.red[100]!;
    if (title.contains('Subscriptions')) return Colors.purple[100]!;
    if (title.contains('Video')) return Colors.green[100]!;

    return Colors.teal[100]!;
  }

  Color _getIconColor(String title) {
    if (title.contains('Manage Categories')) return Colors.amber[800]!;
    if (title.contains('Add Images')) return Colors.indigo[800]!;
    if (title.contains('List')) return Colors.blue[800]!;
    if (title.contains('Users')) return Colors.red[800]!;
    if (title.contains('Subscriptions')) return Colors.purple[800]!;
    if (title.contains('Video')) return Colors.green[800]!;
    return Colors.teal[800]!;
  }

  LinearGradient _gridcolor(String title) {
    if (title.contains('Categories')) {
      return LinearGradient(colors: [Colors.amber[100]!, Colors.amber[200]!]);
    }
    if (title.contains('Images')) {
      return LinearGradient(colors: [Colors.orange[100]!, Colors.orange[200]!]);
    }
    if (title.contains('List')) {
      return LinearGradient(colors: [Colors.blue[100]!, Colors.blue[200]!]);
    }
    if (title.contains('Users')) {
      return LinearGradient(colors: [Colors.red[100]!, Colors.red[200]!]);
    }
    if (title.contains('Subscriptions')) {
      return LinearGradient(colors: [Colors.purple[100]!, Colors.purple[200]!]);
    }
    if (title.contains('Video')) {
      return LinearGradient(colors: [Colors.green[100]!, Colors.green[200]!]);
    }

    return LinearGradient(colors: [Colors.teal[100]!, Colors.teal[200]!]);
  }
}
