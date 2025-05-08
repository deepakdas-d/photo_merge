import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:photomerge/Admin/adminhome.dart';
import 'package:photomerge/Authentication/signin.dart';
import 'package:photomerge/User/View/home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Lottie.asset(
                'assets/animations/empty_gallery.json', // Example Lottie animation URL
                width: 100, // Adjust size as needed
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;

          if (user == null) {
            return LoginPage();
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  Map<String, dynamic> userData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  // Check if user is active
                  bool isActive = userData.containsKey('isActive')
                      ? userData['isActive'] as bool
                      : false;

                  // If user is not active, sign them out and show message
                  if (!isActive) {
                    // Using a post-frame callback to avoid build errors
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
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    });

                    // Return loading with Lottie while the sign-out happens
                    return Scaffold(
                      backgroundColor: Colors.white,
                      body: Center(
                        child: Lottie.asset(
                          'assets/animations/empty_gallery.json', // Example Lottie animation URL
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }

                  // User is active, check role and route accordingly
                  String role = userData['role'] ?? 'user';

                  if (role == 'admin') {
                    return AdminDashboard();
                  } else {
                    return UserDashboard();
                  }
                }

                // Document doesn't exist, sign out and return to login
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                });

                return LoginPage();
              }

              // While loading Firestore data
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Lottie.asset(
                    'assets/animations/empty_gallery.json', // Example Lottie animation URL
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        }

        // Default loading state
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Lottie.asset(
              'assets/animations/empty_gallery.json', // Example Lottie animation URL
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
