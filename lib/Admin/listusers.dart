import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  // Function to update user active status in Firestore
  Future<void> _toggleUserStatus(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': !currentStatus,
      });
    } catch (e) {
      print('Error toggling user status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green,
        title: Text(
          'All Users',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final users = snapshot.data!.docs;

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

              // Safely access the isActive field with a default value of true
              final isActive = userData.containsKey('isActive')
                  ? userData['isActive'] as bool
                  : true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.green
                          .withOpacity(0.1), // Background circle color
                      child: Icon(
                        Icons.person,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  title: Text(email),
                  subtitle: Text('Role: $role'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggle switch
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (newValue) {
                          _toggleUserStatus(docId, isActive);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
