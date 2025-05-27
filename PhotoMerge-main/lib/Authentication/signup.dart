// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart'
//     as flutterSecureStorage;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:lottie/lottie.dart';
// import 'package:uuid/uuid.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class SignupPage extends StatefulWidget {
//   @override
//   _SignupPageState createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _otpController = TextEditingController();

//   final FocusNode _phoneFocusNode = FocusNode();
//   final FocusNode _emailFocusNode = FocusNode();
//   final FocusNode _passwordFocusNode = FocusNode();
//   final FocusNode _confirmPasswordFocusNode = FocusNode();
//   final FocusNode _otpFocusNode = FocusNode();

//   bool _isLoading = false;
//   String? _error;
//   bool _passwordVisible = false;
//   bool _confirmPasswordVisible = false;

//   // Replace with your Django backend URL
//   final String _baseUrl = 'http://127.0.0.1:8000';

//   // Validators
//   String? validateEmail(String? value) {
//     if (value == null || value.isEmpty) return 'Email is required';
//     if (value.length > 254) return 'Email is too long';
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
//     return null;
//   }

//   String? validatePhone(String? value) {
//     if (value == null || value.isEmpty) return 'Phone number is required';
//     final phoneRegex = RegExp(r'^[6-9]\d{9}$');
//     if (!phoneRegex.hasMatch(value)) return 'Enter a valid Indian phone number';
//     return null;
//   }

//   String? validatePassword(String? value) {
//     if (value == null || value.isEmpty) return 'Password is required';
//     if (value.length < 6) return 'Password must be at least 6 characters';
//     return null;
//   }

//   String? validateConfirmPassword(String? value) {
//     if (value != _passwordController.text) return 'Passwords do not match';
//     return null;
//   }

//   String? validateOTP(String? value) {
//     if (value == null || value.isEmpty) return 'OTP is required';
//     if (value.length != 6) return 'OTP must be 6 digits';
//     return null;
//   }

//   Future<void> _signup() async {
//     if (!_formKey.currentState!.validate()) return;

//     final email = _emailController.text.trim().toLowerCase();
//     final password = _passwordController.text;
//     final confirmPassword = _confirmPasswordController.text;
//     final phone = _phoneController.text.trim();

//     if (email.isEmpty || password.isEmpty || phone.isEmpty) {
//       setState(() {
//         _error = 'Please fill in all fields';
//       });
//       return;
//     }

//     if (password != confirmPassword) {
//       setState(() {
//         _error = 'Passwords do not match';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       // Check for duplicate phone number
//       final phoneCheck = await FirebaseFirestore.instance
//           .collection('users')
//           .where('phone', isEqualTo: phone)
//           .limit(1)
//           .get();

//       if (phoneCheck.docs.isNotEmpty) {
//         setState(() {
//           _error = 'This phone number is already registered';
//           _isLoading = false;
//         });
//         return;
//       }

//       // Create user with Firebase Auth
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // Send OTP to email
//       final response = await http.post(
//         Uri.parse('$_baseUrl/send-otp/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'email': email}),
//       );

//       if (response.statusCode == 200) {
//         // Show OTP dialog and wait for verification
//         _showOTPDialog(email, userCredential.user!, phone);
//       } else {
//         // Delete Firebase Auth user if OTP sending fails
//         await userCredential.user!.delete();
//         setState(() {
//           _error = jsonDecode(response.body)['error'] ?? 'Failed to send OTP';
//           _isLoading = false;
//         });
//       }
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'An error occurred during sign up';

//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'This email is already registered';
//       } else if (e.code == 'weak-password') {
//         errorMessage = 'The password is too weak';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Please enter a valid email address';
//       }

//       setState(() {
//         _error = errorMessage;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Error: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   void _showOTPDialog(String email, User user, String phone) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Enter OTP'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('An OTP has been sent to $email'),
//               SizedBox(height: 10),
//               TextFormField(
//                 controller: _otpController,
//                 focusNode: _otpFocusNode,
//                 decoration: InputDecoration(
//                   hintText: 'Enter 6-digit OTP',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(6),
//                 ],
//                 validator: validateOTP,
//               ),
//               if (_error != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8.0),
//                   child: Text(
//                     _error!,
//                     style: TextStyle(color: Colors.red[700]),
//                   ),
//                 ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 // Delete Firebase Auth user if user cancels OTP verification
//                 await user.delete();
//                 Navigator.of(context).pop();
//                 setState(() {
//                   _isLoading = false;
//                 });
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 if (_otpController.text.isEmpty ||
//                     _otpController.text.length != 6) {
//                   setState(() {
//                     _error = 'Please enter a valid 6-digit OTP';
//                   });
//                   return;
//                 }

//                 setState(() {
//                   _isLoading = true;
//                   _error = null;
//                 });

//                 try {
//                   final response = await http.post(
//                     Uri.parse('$_baseUrl/verify-otp/'),
//                     headers: {'Content-Type': 'application/json'},
//                     body: jsonEncode({
//                       'email': email,
//                       'otp': _otpController.text,
//                     }),
//                   );

//                   if (response.statusCode == 200) {
//                     // Save user info in Firestore only after OTP is verified
//                     await FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(user.uid)
//                         .set({
//                       'email': email,
//                       'phone': phone,
//                       'role': "user",
//                       'isActive': true,
//                       'isSubscribed': false,
//                       'freeDownloadUsed': false,
//                       'subscriptionPlan': '',
//                       'subscriptionExpiry': null,
//                       'createdAt': FieldValue.serverTimestamp(),
//                       'emailVerified': true,
//                       'profile_status': false,
//                     });

//                     Navigator.of(context).pop();
//                     Navigator.pushNamedAndRemoveUntil(
//                         context, '/profile', (route) => false);
//                   } else {
//                     // Delete Firebase Auth user if OTP verification fails
//                     await user.delete();
//                     setState(() {
//                       _error = jsonDecode(response.body)['error'] ??
//                           'Failed to verify OTP';
//                     });
//                   }
//                 } catch (e) {
//                   // Delete Firebase Auth user on error
//                   await user.delete();
//                   setState(() {
//                     _error = 'Error verifying OTP: $e';
//                   });
//                 } finally {
//                   setState(() {
//                     _isLoading = false;
//                   });
//                 }
//               },
//               child: Text('Verify'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<String> _getDeviceId() async {
//     try {
//       DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

//       if (Platform.isAndroid) {
//         AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//         return androidInfo.id;
//       } else if (Platform.isIOS) {
//         IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//         return iosInfo.identifierForVendor!;
//       } else if (kIsWeb) {
//         const storage = flutterSecureStorage.FlutterSecureStorage();
//         String? deviceId = await storage.read(key: 'device_id');

//         if (deviceId == null) {
//           deviceId = Uuid().v4();
//           await storage.write(key: 'device_id', value: deviceId);
//         }

//         return deviceId;
//       }

//       return 'unknown_device';
//     } catch (e) {
//       return DateTime.now().millisecondsSinceEpoch.toString();
//     }
//   }

//   Future<void> logout() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .update({
//           'isLoggedIn': false,
//           'deviceId': '',
//         });
//       }
//       await FirebaseAuth.instance.signOut();
//     } catch (e) {
//       print('Error during logout: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _phoneController.dispose();
//     _otpController.dispose();
//     _emailFocusNode.dispose();
//     _phoneFocusNode.dispose();
//     _passwordFocusNode.dispose();
//     _confirmPasswordFocusNode.dispose();
//     _otpFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             child: Container(
//               child: Column(
//                 children: <Widget>[
//                   Container(
//                     height: 400,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         image: AssetImage('assets/images/background.png'),
//                         fit: BoxFit.fill,
//                       ),
//                     ),
//                     child: Stack(
//                       children: <Widget>[
//                         Positioned(
//                           left: 30,
//                           width: 80,
//                           height: 200,
//                           child: FadeInUp(
//                             duration: Duration(seconds: 1),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                   image:
//                                       AssetImage('assets/images/light-1.png'),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           left: 140,
//                           width: 80,
//                           height: 150,
//                           child: FadeInUp(
//                             duration: Duration(milliseconds: 1200),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                   image:
//                                       AssetImage('assets/images/light-2.png'),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           right: 40,
//                           top: 40,
//                           width: 80,
//                           height: 150,
//                           child: FadeInUp(
//                             duration: Duration(milliseconds: 1300),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 image: DecorationImage(
//                                   image: AssetImage('assets/images/clock.png'),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           child: FadeInUp(
//                             duration: Duration(milliseconds: 1600),
//                             child: Container(
//                               margin: EdgeInsets.only(top: 50),
//                               child: Center(
//                                 child: Text(
//                                   "Sign Up",
//                                   style: GoogleFonts.poppins(
//                                     color: Colors.white,
//                                     fontSize: 40,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.all(30.0),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         children: <Widget>[
//                           FadeInUp(
//                             duration: Duration(milliseconds: 1800),
//                             child: Column(
//                               children: <Widget>[
//                                 // Email TextField
//                                 Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 8.0, vertical: 4.0),
//                                   child: TextFormField(
//                                     controller: _emailController,
//                                     focusNode: _emailFocusNode,
//                                     textInputAction: TextInputAction.next,
//                                     onFieldSubmitted: (_) {
//                                       FocusScope.of(context)
//                                           .requestFocus(_phoneFocusNode);
//                                     },
//                                     decoration: InputDecoration(
//                                       hintText: "Email",
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700]),
//                                       border: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                       enabledBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color: Color.fromRGBO(
//                                               143, 148, 251, 0.5),
//                                         ),
//                                       ),
//                                       focusedBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                     ),
//                                     keyboardType: TextInputType.emailAddress,
//                                     validator: validateEmail,
//                                   ),
//                                 ),
//                                 SizedBox(height: 10),
//                                 // Phone TextField
//                                 Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 8.0, vertical: 4.0),
//                                   child: TextFormField(
//                                     controller: _phoneController,
//                                     focusNode: _phoneFocusNode,
//                                     textInputAction: TextInputAction.next,
//                                     onFieldSubmitted: (_) {
//                                       FocusScope.of(context)
//                                           .requestFocus(_passwordFocusNode);
//                                     },
//                                     decoration: InputDecoration(
//                                       hintText: "Phone number",
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700]),
//                                       border: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                       enabledBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color: Color.fromRGBO(
//                                               143, 148, 251, 0.5),
//                                         ),
//                                       ),
//                                       focusedBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                     ),
//                                     keyboardType: TextInputType.phone,
//                                     inputFormatters: [
//                                       FilteringTextInputFormatter.digitsOnly,
//                                       LengthLimitingTextInputFormatter(10),
//                                     ],
//                                     validator: validatePhone,
//                                   ),
//                                 ),
//                                 SizedBox(height: 10),
//                                 // Password TextField
//                                 Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 8.0, vertical: 4.0),
//                                   child: TextFormField(
//                                     controller: _passwordController,
//                                     focusNode: _passwordFocusNode,
//                                     textInputAction: TextInputAction.next,
//                                     onFieldSubmitted: (_) {
//                                       FocusScope.of(context).requestFocus(
//                                           _confirmPasswordFocusNode);
//                                     },
//                                     obscureText: !_passwordVisible,
//                                     decoration: InputDecoration(
//                                       hintText: "Password",
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700]),
//                                       border: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                       enabledBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color: Color.fromRGBO(
//                                               143, 148, 251, 0.5),
//                                         ),
//                                       ),
//                                       focusedBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(
//                                           _passwordVisible
//                                               ? Icons.visibility_off
//                                               : Icons.visibility,
//                                           color: Colors.grey[600],
//                                         ),
//                                         onPressed: () {
//                                           setState(() {
//                                             _passwordVisible =
//                                                 !_passwordVisible;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                     validator: validatePassword,
//                                   ),
//                                 ),
//                                 SizedBox(height: 10),
//                                 // Confirm Password TextField
//                                 Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 8.0, vertical: 4.0),
//                                   child: TextFormField(
//                                     controller: _confirmPasswordController,
//                                     focusNode: _confirmPasswordFocusNode,
//                                     textInputAction: TextInputAction.done,
//                                     obscureText: !_confirmPasswordVisible,
//                                     decoration: InputDecoration(
//                                       hintText: "Confirm Password",
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700]),
//                                       border: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                       enabledBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color: Color.fromRGBO(
//                                               143, 148, 251, 0.5),
//                                         ),
//                                       ),
//                                       focusedBorder: UnderlineInputBorder(
//                                         borderSide: BorderSide(
//                                           color:
//                                               Color.fromRGBO(143, 148, 251, 1),
//                                         ),
//                                       ),
//                                       suffixIcon: IconButton(
//                                         icon: Icon(
//                                           _confirmPasswordVisible
//                                               ? Icons.visibility_off
//                                               : Icons.visibility,
//                                           color: Colors.grey[600],
//                                         ),
//                                         onPressed: () {
//                                           setState(() {
//                                             _confirmPasswordVisible =
//                                                 !_confirmPasswordVisible;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                     validator: validateConfirmPassword,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (_error != null)
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(vertical: 10.0),
//                               child: FadeInUp(
//                                 duration: Duration(milliseconds: 1800),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red[50],
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(color: Colors.red[200]!),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Icon(Icons.error_outline,
//                                           color: Colors.red[700]),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: Text(
//                                           _error!,
//                                           style:
//                                               TextStyle(color: Colors.red[700]),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           SizedBox(height: 30),
//                           FadeInUp(
//                             duration: Duration(milliseconds: 1900),
//                             child: GestureDetector(
//                               onTap: _isLoading ? null : _signup,
//                               child: Container(
//                                 height: 50,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(10),
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       Color(0xFF00A19A),
//                                       Color(0x9900A19A),
//                                     ],
//                                   ),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     "Create Account",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 20),
//                           FadeInUp(
//                             duration: Duration(milliseconds: 2100),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "Already have an account? ",
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 TextButton(
//                                   onPressed: () =>
//                                       Navigator.pushReplacementNamed(
//                                           context, '/login'),
//                                   child: Text(
//                                     "Login",
//                                     style: TextStyle(
//                                       color: Color.fromRGBO(143, 148, 251, 1),
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.black54,
//               child: Center(
//                 child: SizedBox(
//                   width: 100,
//                   height: 100,
//                   child: Lottie.asset('assets/animations/empty_gallery.json'),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as flutterSecureStorage;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _otpSent = false;
  bool _isVerifyingOtp = false;

  // Validators
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (value.length > 254) return 'Email is too long';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid Indian phone number';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    return null;
  }

  // Send OTP API call
  Future<bool> _sendOtp(String email) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var request =
          http.Request('POST', Uri.parse('http://192.168.20.8:8000/send-otp/'));
      request.body = json.encode({"email": email});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('OTP sent successfully: $responseBody');
        return true;
      } else {
        print('Failed to send OTP: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP API call
  Future<bool> _verifyOtp(String email, String otp) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
          'POST', Uri.parse('http://192.168.20.8:8000/verify-otp/'));
      request.body = json.encode({"email": email, "otp": otp});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('OTP verified successfully: $responseBody');
        return true;
      } else {
        print('Failed to verify OTP: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Show OTP dialog
  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Verify Email',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'We have sent a 6-digit OTP to your email address. Please enter it below to verify your email.',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit OTP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color.fromRGBO(143, 148, 251, 1),
                        ),
                      ),
                    ),
                    validator: validateOtp,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isVerifyingOtp
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          setState(() {
                            _otpSent = false;
                            _isLoading = false;
                            _error = null;
                          });
                        },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isVerifyingOtp
                      ? null
                      : () async {
                          if (_otpController.text.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please enter a valid 6-digit OTP'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            _isVerifyingOtp = true;
                          });

                          bool otpVerified = await _verifyOtp(
                            _emailController.text.trim().toLowerCase(),
                            _otpController.text,
                          );

                          if (otpVerified) {
                            Navigator.of(context).pop();
                            await _createFirebaseAccount();
                          } else {
                            setDialogState(() {
                              _isVerifyingOtp = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid OTP. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(143, 148, 251, 1),
                  ),
                  child: _isVerifyingOtp
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Verify', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Create Firebase account after OTP verification
  Future<void> _createFirebaseAccount() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Create user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user info in Firestore with emailVerified: true
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'phone': phone,
        'role': "user",
        'isActive': true,
        'isSubscribed': false,
        'freeDownloadUsed': false,
        'subscriptionPlan': '',
        'subscriptionExpiry': null,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': true, // Set to true since OTP is verified
        'profile_status': false,
      });

      // Navigate to profile page
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during account creation';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Updated signup method
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields';
      });
      return;
    }

    if (password != confirmPassword) {
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
      // Check for duplicate phone number
      final phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        setState(() {
          _error = 'This phone number is already registered';
          _isLoading = false;
        });
        return;
      }

      // Check for duplicate email
      final emailCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailCheck.docs.isNotEmpty) {
        setState(() {
          _error = 'This email is already registered';
          _isLoading = false;
        });
        return;
      }

      // Send OTP
      bool otpSent = await _sendOtp(email);

      if (otpSent) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _showOtpDialog();
      } else {
        setState(() {
          _error = 'Failed to send OTP. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor!;
      } else if (kIsWeb) {
        const storage = flutterSecureStorage.FlutterSecureStorage();
        String? deviceId = await storage.read(key: 'device_id');

        if (deviceId == null) {
          deviceId = Uuid().v4();
          await storage.write(key: 'device_id', value: deviceId);
        }

        return deviceId;
      }

      return 'unknown_device';
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              child: Column(
                children: <Widget>[
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/background.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 30,
                          width: 80,
                          height: 200,
                          child: FadeInUp(
                            duration: Duration(seconds: 1),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/light-1.png'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 140,
                          width: 80,
                          height: 150,
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1200),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/light-2.png'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          top: 40,
                          width: 80,
                          height: 150,
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1300),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/clock.png'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1600),
                            child: Container(
                              margin: EdgeInsets.only(top: 50),
                              child: Center(
                                child: Text(
                                  "Sign Up",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          if (_otpSent)
                            FadeInUp(
                              duration: Duration(milliseconds: 1800),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'OTP sent successfully! Please check your email.',
                                        style:
                                            TextStyle(color: Colors.green[700]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          FadeInUp(
                            duration: Duration(milliseconds: 1800),
                            child: Column(
                              children: <Widget>[
                                // Email TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_phoneFocusNode);
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: validateEmail,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Phone TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_passwordFocusNode);
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Phone number",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: validatePhone,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Password TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(
                                          _confirmPasswordFocusNode);
                                    },
                                    obscureText: !_passwordVisible,
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisible =
                                                !_passwordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: validatePassword,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Confirm Password TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmPasswordFocusNode,
                                    textInputAction: TextInputAction.done,
                                    obscureText: !_confirmPasswordVisible,
                                    decoration: InputDecoration(
                                      hintText: "Confirm Password",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
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
                                    ),
                                    validator: validateConfirmPassword,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: FadeInUp(
                                duration: Duration(milliseconds: 1800),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style:
                                              TextStyle(color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 30),
                          FadeInUp(
                            duration: Duration(milliseconds: 1900),
                            child: GestureDetector(
                              onTap: _isLoading ? null : _signup,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF00A19A),
                                      Color(0x9900A19A),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          FadeInUp(
                            duration: Duration(milliseconds: 2100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/login'),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset('assets/animations/empty_gallery.json'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
