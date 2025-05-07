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
    _filteredActions = List.from(_allActions); // Create a copy of the list
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
    if (query.isEmpty) {
      setState(() {
        _filteredActions = List.from(_allActions);
      });
      return;
    }

    final filtered = _allActions.where((action) {
      final title = action['title'].toString().toLowerCase();
      final subtitle = action['subtitle'].toString().toLowerCase();
      final searchLower = query.toLowerCase();
      return title.contains(searchLower) || subtitle.contains(searchLower);
    }).toList();

    setState(() {
      _filteredActions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _filteredActions = List.from(_allActions);
              }
            });
          },
          icon: Icon(_isSearching ? Icons.close : Icons.search),
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
            Text(
              _filteredActions.isEmpty
                  ? 'No results found'
                  : 'Manage your photo gallery:',
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
                    : ListView.builder(
                        itemCount: _filteredActions.length,
                        itemBuilder: (context, index) {
                          final action = _filteredActions[index];
                          return _buildActionTile(
                            context,
                            icon: action['icon'] as IconData,
                            title: action['title'] as String,
                            subtitle: action['subtitle'] as String,
                            onTap: () {
                              // Call the onTap function with context
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ));
  }
}
