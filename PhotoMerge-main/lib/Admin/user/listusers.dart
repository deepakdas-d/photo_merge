// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:photomerge/Admin/user/user_details.dart';

// class UserListPage extends StatefulWidget {
//   const UserListPage({super.key});

//   @override
//   State<UserListPage> createState() => _UserListPageState();
// }

// class _UserListPageState extends State<UserListPage> {
//   void _refreshUserList() {
//     setState(() {});
//   }

//   Future<void> _setUserStatus(String docId, bool newStatus) async {
//     try {
//       await FirebaseFirestore.instance.collection('users').doc(docId).update({
//         'isActive': newStatus,
//       });
//     } catch (e) {
//       print('Error setting user status: $e');
//     }
//   }

//   Future<Map<String, dynamic>?> _getUserProfile(String docId) async {
//     try {
//       final profileDoc = await FirebaseFirestore.instance
//           .collection('user_profile')
//           .doc(docId)
//           .get();

//       if (profileDoc.exists) {
//         return profileDoc.data() as Map<String, dynamic>;
//       }
//     } catch (e) {
//       print('Error fetching profile data: $e');
//     }
//     return null;
//   }

//   bool isProfileComplete(
//       Map<String, dynamic> data, List<String> requiredFields) {
//     for (String field in requiredFields) {
//       if (data[field] == null || data[field].toString().trim().isEmpty) {
//         return false;
//       }
//     }
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: Color(0xFF00B6B0),
//         title: Text(
//           'All Users',
//           style: GoogleFonts.oswald(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _refreshUserList,
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           // final users = snapshot.data!.docs; // this is for all the account

//           final users = snapshot.data!.docs.where((doc) {
//             final data =
//                 doc.data() as Map<String, dynamic>; //this for admin filtering
//             return data['role'] != 'admin'; // Exclude admins
//           }).toList();

//           if (users.isEmpty) {
//             return const Center(child: Text('No users found.'));
//           }

//           return ListView.builder(
//             itemCount: users.length,
//             itemBuilder: (context, index) {
//               final userDoc = users[index];
//               final userData = userDoc.data() as Map<String, dynamic>;
//               final docId = userDoc.id;
//               final email = userData['email'] ?? 'No email';
//               final role = userData['role'] ?? 'No role';
//               final isActive = userData['isActive'] ?? true;

//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: isActive
//                         ? Colors.green.withOpacity(0.1)
//                         : Colors.red.withOpacity(0.1),
//                     child: Icon(
//                       Icons.person,
//                       color: isActive ? Colors.green : Colors.red,
//                     ),
//                   ),
//                   title: Row(
//                     children: [
//                       Expanded(child: Text(email)),
//                       // IconButton(
//                       //   icon: const Icon(Icons.download, color: Colors.green),
//                       //   onPressed: () =>
//                       //       _downloadUserDetails(context, userData, docId),
//                       //   tooltip: 'Download user details',
//                       // ),
//                     ],
//                   ),
//                   subtitle: Text('Role: $role'),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 12,
//                         height: 12,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: isActive ? Colors.green : Colors.red,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Switch(
//                         value: isActive,
//                         activeColor: Colors.green,
//                         onChanged: (newValue) =>
//                             _setUserStatus(docId, newValue),
//                       ),
//                     ],
//                   ),
//                   onTap: () async {
//                     final profileData = await _getUserProfile(docId);

//                     if (profileData == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('No user profile data found.'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                       return; // Stop execution if data is null
//                     }

//                     // If not null, navigate to the next page
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => UserDetailsPage(
//                           profileData: profileData,
//                           userData: userData,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/Admin/user/user_details.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

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

  Future<void> _downloadAllUsersData() async {
    // Show progress loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      // Fetch all users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['role'] != 'admin'; // Exclude admins
      }).toList();

      if (users.isEmpty) {
        Navigator.of(context).pop(); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No users found to download.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Fetch profile data for all users
      final userDataWithProfiles = <Map<String, dynamic>>[];
      for (var userDoc in users) {
        final userData = userDoc.data();
        final docId = userDoc.id;
        final profileData = await _getUserProfile(docId);
        userDataWithProfiles.add({
          'docId': docId,
          'userData': userData,
          'profileData': profileData,
        });
      }

      // Sort by full name (firstName + lastName)
      userDataWithProfiles.sort((a, b) {
        final profileA = a['profileData'] as Map<String, dynamic>?;
        final profileB = b['profileData'] as Map<String, dynamic>?;
        final fullNameA =
            '${profileA?['firstName'] ?? ''} ${profileA?['lastName'] ?? ''}'
                .trim();
        final fullNameB =
            '${profileB?['firstName'] ?? ''} ${profileB?['lastName'] ?? ''}'
                .trim();
        return fullNameA.compareTo(fullNameB);
      });

      // Create PDF document
      final pdf = pw.Document();

      // Add user data to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'All Users Data',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              ...userDataWithProfiles.map((user) {
                final userData = user['userData'] as Map<String, dynamic>;
                final profileData =
                    user['profileData'] as Map<String, dynamic>?;

                // Combine firstName and lastName
                final fullName = profileData != null
                    ? '${profileData['firstName'] ?? 'N/A'} ${profileData['lastName'] ?? 'N/A'}'
                        .trim()
                    : 'N/A';

                // Extract fields
                final phoneNumber = profileData?['phone']?.toString() ?? 'N/A';
                final email = userData['email']?.toString() ?? 'N/A';
                final companyName =
                    profileData?['companyName']?.toString() ?? 'N/A';
                final designation =
                    profileData?['designation']?.toString() ?? 'N/A';
                final district = profileData?['district']?.toString() ?? 'N/A';
                final branch = profileData?['branch']?.toString() ?? 'N/A';
                final subscriptionPlan =
                    userData['subscriptionPlan']?.toString() ?? 'N/A';
                final subscriptionPrice =
                    userData['subscriptionPrice']?.toString() ?? 'N/A';
                final status =
                    (userData['isActive'] ?? true) ? 'Active' : 'Inactive';

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Name: $fullName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Phone Number: $phoneNumber'),
                    pw.Text('Email: $email'),
                    pw.Text('Company Name: $companyName'),
                    pw.Text('Designation: $designation'),
                    pw.Text('District: $district'),
                    pw.Text('Branch: $branch'),
                    pw.Text('Subscription Plan: $subscriptionPlan'),
                    pw.Text('Subscription Price: $subscriptionPrice'),
                    pw.Text('Status: $status'),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ];
          },
        ),
      );

      // Save PDF to app-specific documents directory
      final outputDir = await getApplicationDocumentsDirectory();
      final file = File(
          '${outputDir.path}/all_users_data_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close loader
      Navigator.of(context).pop();

      // Show dialog to open PDF
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('PDF Generated'),
          content: Text(
              'PDF has been saved to app documents directory. Would you like to open it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                final result = await OpenFile.open(file.path);
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open PDF: ${result.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Open'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loader if open
      Navigator.of(context).pop();
      print('Error downloading users data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadAllUsersData,
            tooltip: 'Download all users data as PDF',
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

          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
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
                      return;
                    }

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
