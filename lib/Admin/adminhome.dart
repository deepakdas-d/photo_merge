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
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          Container(
              decoration: BoxDecoration(
                color: Colors.green, // Background color of the circle
                shape: BoxShape.circle,
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.3),
                //     spreadRadius: 1,
                //     blurRadius: 6,
                //     offset: Offset(0, 0.5), // changes position of shadow
                //   ),
                // ]
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Sign Out',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor:
                            Colors.green[50], // Light green background
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
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _signOut();
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );
                },
              )),
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
              child: Text(
                'Welcome, ${_adminEmail ?? 'Admin'}!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Manage your photo gallery:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Updated Action Cards wrapped in white box
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
                child: ListView(
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.category,
                      title: 'Manage Categories',
                      subtitle:
                          'Add, edit, or delete categories and subcategories.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CategoryManagementPage()),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.add_photo_alternate,
                      title: 'Add Images',
                      subtitle: 'Upload new images to the gallery.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddImagePage()),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.image,
                      title: 'List Images',
                      subtitle: 'View and manage all uploaded images.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ListImagesPage()),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.person_add,
                      title: 'Add Admin',
                      subtitle: 'Create a new admin account.',
                      onTap: () {
                        Navigator.pushNamed(context, '/createadmin');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.person_add,
                      title: 'List Users',
                      subtitle: 'List all users.',
                      onTap: () {
                        Navigator.pushNamed(context, '/listusers');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.money_rounded,
                      title: 'Subscriptions',
                      subtitle: 'Manage subscriptions.',
                      onTap: () {
                        Navigator.pushNamed(context, '/submanage');
                      },
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.money_rounded,
                      title: 'Carousel',
                      subtitle: 'Manage carousel items.',
                      onTap: () {
                        Navigator.pushNamed(context, '/carousel');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    return Card(
        color: Colors.white,
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Container(
            width: 48, // Equal width and height for a square background
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green,
              shape:
                  BoxShape.circle, // Or use borderRadius for rounded rectangle
            ),
            alignment: Alignment.center, // Center the icon within the container
            child: Icon(icon,
                size: 24,
                color: Colors.white), // Smaller icon for visual balance
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ));
  }
}
