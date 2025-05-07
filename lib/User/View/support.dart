
import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Need help? Contact us through the following channels:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email: support@example.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone: +1 (123) 456-7890'),
            ),
            ListTile(
              leading: Icon(Icons.web),
              title: Text('Website: www.example.com'),
            ),
          ],
        ),
      ),
    );
  }
}