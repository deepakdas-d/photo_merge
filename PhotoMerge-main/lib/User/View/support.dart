import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/home.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Support',
          style: GoogleFonts.poppins(
            color: Color(0xFF00A19A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDashboard(),
                  ));
            },
            icon: Icon(
              Icons.arrow_back,
            ),
            color: Color(0xFF00A19A)),
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
              title: Text('Email: Creativeacademy5265@gmail.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone: +91 8075691175'),
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
