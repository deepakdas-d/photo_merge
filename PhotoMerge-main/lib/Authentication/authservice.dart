// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:photomerge/Admin/adminhome.dart';
// import 'package:photomerge/Authentication/signin.dart';
// import 'package:photomerge/User/View/home.dart';
// import 'package:photomerge/User/View/profile.dart';

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildLoadingScreen();
//         }

//         if (snapshot.hasData) {
//           User user = snapshot.data!;
//           return StreamBuilder<DocumentSnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(user.uid)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return _buildLoadingScreen();
//               }

//               if (!snapshot.hasData || !snapshot.data!.exists) {
//                 // If user document doesn't exist, navigate to ProfilePage
//                 return const ProfilePage();
//               }

//               Map<String, dynamic> userData =
//                   snapshot.data!.data() as Map<String, dynamic>;

//               // Check if user is active
//               bool isActive = userData['isActive'] ?? false;
//               if (!isActive) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) async {
//                   await FirebaseAuth.instance.signOut();
//                   if (context.mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                             'Your account has been deactivated. Please contact support.'),
//                         backgroundColor: Colors.red,
//                         duration: Duration(seconds: 5),
//                       ),
//                     );
//                     Navigator.of(context).pushReplacement(
//                         MaterialPageRoute(builder: (_) => LoginPage()));
//                   }
//                 });
//                 return _buildLoadingScreen();
//               }

//               // Check profile_status
//               bool profileStatus = userData['profile_status'] ?? false;

//               if (!profileStatus) {
//                 return const ProfilePage();
//               }

//               // User is active and has a complete profile, check role
//               String role = userData['role'] ?? 'user';
//               return role == 'admin'
//                   ? const AdminDashboard()
//                   : const UserDashboard();
//             },
//           );
//         }

//         // User is not signed in
//         return LoginPage();
//       },
//     );
//   }

//   Widget _buildLoadingScreen() {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Lottie.asset(
//           'assets/animations/empty_gallery.json',
//           width: 100,
//           height: 100,
//           fit: BoxFit.contain,
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:photomerge/Admin/adminhome.dart';
import 'package:photomerge/Authentication/signin.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:photomerge/User/View/profile.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData) {
          User user = snapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                // If user document doesn't exist, navigate to ProfilePage
                return const ProfilePage();
              }

              Map<String, dynamic> userData =
                  snapshot.data!.data() as Map<String, dynamic>;

              // Check user role
              String role = userData['role'] ?? 'user';
              if (role == 'admin') {
                return const AdminDashboard();
              }

              // For non-admin users, check if user is active
              bool isActive = userData['isActive'] ?? false;
              if (!isActive) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Your account has been deactivated. Please contact support.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => LoginPage()));
                  }
                });
                return _buildLoadingScreen();
              }

              // Check profile_status
              bool profileStatus = userData['profile_status'] ?? false;

              if (!profileStatus) {
                return const ProfilePage();
              }

              // User is active and has a complete profile
              return const UserDashboard();
            },
          );
        }

        // User is not signed in
        return LoginPage();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/animations/empty_gallery.json',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
