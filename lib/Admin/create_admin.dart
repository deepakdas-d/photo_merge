import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomerge/main.dart';

class create_admin extends StatefulWidget {
  @override
  _create_adminState createState() => _create_adminState();
}

class _create_adminState extends State<create_admin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _createAdmin() async {
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
        'role': 'admin',
      });

      setState(() {
        _emailController.clear();
        _passwordController.clear();
        _error = 'Admin created successfully!';
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
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text('Create New Admin',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                        color: _error!.contains('successfully')
                            ? Colors.green
                            : Colors.red),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createAdmin,
                  child: const Text('Create Admin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
