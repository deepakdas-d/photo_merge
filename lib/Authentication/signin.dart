// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:photomerge/main.dart';

// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   String? _error;

//   Future<void> _login() async {
//     // Validate inputs
//     if (_emailController.text.trim().isEmpty ||
//         _passwordController.text.trim().isEmpty) {
//       setState(() {
//         _error = 'Please enter both email and password';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       // First attempt to sign in with Firebase Auth
//       UserCredential userCredential =
//           await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       // Check if user is active in Firestore
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .get();

//       if (!userDoc.exists) {
//         // User document doesn't exist in Firestore
//         await FirebaseAuth.instance.signOut();
//         setState(() {
//           _error = 'Account not found. Please contact support.';
//         });
//         return;
//       }

//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

//       // Check if isActive field exists and is true
//       bool isActive = userData.containsKey('isActive')
//           ? userData['isActive'] as bool
//           : false;

//       if (!isActive) {
//         // If user is not active, sign them out and show error
//         await FirebaseAuth.instance.signOut();
//         setState(() {
//           _error = 'Your account has been disabled. Please contact support.';
//         });
//       } else {
//         // User is active, proceed to appropriate dashboard based on role
//         if (mounted) {
//           Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'An error occurred during sign in';

//       if (e.code == 'user-not-found') {
//         errorMessage = 'No user found with this email';
//       } else if (e.code == 'wrong-password') {
//         errorMessage = 'Incorrect password';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email address';
//       } else if (e.code == 'user-disabled') {
//         errorMessage = 'This account has been disabled';
//       } else if (e.code == 'too-many-requests') {
//         errorMessage = 'Too many failed login attempts. Try again later';
//       }

//       setState(() {
//         _error = errorMessage;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: LoadingOverlay(
//         isLoading: _isLoading,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 'Welcome Back',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),
//               TextField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.email),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.lock),
//                 ),
//                 obscureText: true,
//               ),
//               if (_error != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 16.0),
//                   child: Text(
//                     _error!,
//                     style: const TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _login,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Login',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextButton(
//                 onPressed: () => Navigator.pushNamed(context, '/signup'),
//                 child: const Text('Need an account? Sign Up'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:photomerge/main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;

  Future<void> _login() async {
    // Validate inputs
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First attempt to sign in with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if user is active in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // User document doesn't exist in Firestore
        await FirebaseAuth.instance.signOut();
        setState(() {
          _error = 'Account not found. Please contact support.';
        });
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Check if isActive field exists and is true
      bool isActive = userData.containsKey('isActive')
          ? userData['isActive'] as bool
          : false;

      if (!isActive) {
        // If user is not active, sign them out and show error
        await FirebaseAuth.instance.signOut();
        setState(() {
          _error = 'Your account has been disabled. Please contact support.';
        });
      } else {
        // User is active, proceed to appropriate dashboard based on role
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many failed login attempts. Try again later';
      }

      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                height: size.height - 40, // Account for SafeArea
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 1),
                    // App logo or icon here
                    Icon(
                      Icons.photo_camera,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Email field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.email_outlined,
                            color: colorScheme.primary),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    // Password field
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        prefixIcon: Icon(Icons.lock_outline,
                            color: colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      obscureText: !_passwordVisible,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
