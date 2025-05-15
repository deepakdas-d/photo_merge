import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/Admin/user/user_details.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  void _refreshUserList() {
    setState(() {});
  }

  Future<void> _setUserStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': newStatus,
      });
    } catch (e) {
      print('Error setting user status: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String docId) async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(docId)
          .get();

      if (profileDoc.exists) {
        return profileDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
    return null;
  }

  bool isProfileComplete(
      Map<String, dynamic> data, List<String> requiredFields) {
    for (String field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF00B6B0),
        title: Text(
          'All Users',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshUserList,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // final users = snapshot.data!.docs; // this is for all the account

          final users = snapshot.data!.docs.where((doc) {
            final data =
                doc.data() as Map<String, dynamic>; //this for admin filtering
            return data['role'] != 'admin'; // Exclude admins
          }).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final docId = userDoc.id;
              final email = userData['email'] ?? 'No email';
              final role = userData['role'] ?? 'No role';
              final isActive = userData['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(email)),
                      // IconButton(
                      //   icon: const Icon(Icons.download, color: Colors.green),
                      //   onPressed: () =>
                      //       _downloadUserDetails(context, userData, docId),
                      //   tooltip: 'Download user details',
                      // ),
                    ],
                  ),
                  subtitle: Text('Role: $role'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (newValue) =>
                            _setUserStatus(docId, newValue),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final profileData = await _getUserProfile(docId);

                    if (profileData == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No user profile data found.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return; // Stop execution if data is null
                    }

                    // If not null, navigate to the next page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailsPage(
                          profileData: profileData,
                          userData: userData,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
