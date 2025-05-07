// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:photomerge/main.dart';

// class SignupPage extends StatefulWidget {
//   @override
//   _SignupPageState createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   String _selectedRole = 'user';
//   bool _isLoading = false;
//   String? _error;

//   Future<void> _signup() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .set({
//         'email': _emailController.text.trim(),
//         'role': _selectedRole,
//         'isActive': true,
//         'isSubscribed': false,
//         'freeDownloadUsed': false,
//         'subscriptionPlan': '',
//         'subscriptionExpiry': null,
//       });

//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         '/',
//         (route) => false,
//       );
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
//       appBar: AppBar(title: const Text('Signup')),
//       body: LoadingOverlay(
//         isLoading: _isLoading,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               TextField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(labelText: 'Email'),
//               ),
//               TextField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(labelText: 'Password'),
//                 obscureText: true,
//               ),
//               DropdownButton<String>(
//                 value: _selectedRole,
//                 items: [
//                   'user',
//                 ]
//                     .map((role) => DropdownMenuItem(
//                           value: role,
//                           child: Text(role),
//                         ))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedRole = value!;
//                   });
//                 },
//               ),
//               if (_error != null)
//                 Text(_error!, style: const TextStyle(color: Colors.red)),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _signup,
//                 child: const Text('Sign Up'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pushNamed(context, '/login'),
//                 child: const Text('Already have an account? Login'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomerge/main.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _signup() async {
    // Basic validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please fill in all fields';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'isActive': true,
        'isSubscribed': false,
        'freeDownloadUsed': false,
        'subscriptionPlan': '',
        'subscriptionExpiry': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign up';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

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
                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Create a password',
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
                    const SizedBox(height: 16),

                    // Confirm Password field
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
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
                            _confirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      obscureText: !_confirmPasswordVisible,
                    ),
                    const SizedBox(height: 16),

                    // Role selection (styled as a dropdown)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                isExpanded: true,
                                hint: const Text('Select account type'),
                                items: [
                                  'user',
                                ]
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role.substring(0, 1).toUpperCase() +
                                                role.substring(1),
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
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
                      ),
                    const SizedBox(height: 24),

                    // Sign Up button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          child: Text(
                            'Login',
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
