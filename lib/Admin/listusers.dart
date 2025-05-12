import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  void _refreshUserList() {
    setState(() {});
  }

  Future<void> _toggleUserStatus(String docId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': !currentStatus,
      });
    } catch (e) {
      print('Error toggling user status: $e');
    }
  }

  Future<File> _generatePdf(
      Map<String, dynamic> userData, String userId) async {
    final pdf = pw.Document();

    Map<String, dynamic>? profileData;
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(userId)
          .get();
      if (profileDoc.exists) {
        profileData = profileDoc.data();
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'User Details',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildPdfRow('User ID', userId),
              _buildPdfRow('Email', userData['email'] ?? 'Not provided'),
              _buildPdfRow('Role', userData['role'] ?? 'Not provided'),
              _buildPdfRow('Status',
                  userData['isActive'] == true ? 'Active' : 'Inactive'),
              if (userData['displayName'] != null)
                _buildPdfRow('Name', userData['displayName']),
              if (userData['phoneNumber'] != null)
                _buildPdfRow('Phone', userData['phoneNumber']),
              if (userData['createdAt'] != null)
                _buildPdfRow(
                    'Created', _formatTimestamp(userData['createdAt'])),
              if (profileData != null) ...[
                pw.SizedBox(height: 20),
                pw.Text('Profile Details',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildPdfRow('First Name', profileData['firstName'] ?? ''),
                _buildPdfRow('Last Name', profileData['lastName'] ?? ''),
                _buildPdfRow('Gender', profileData['gender'] ?? ''),
                _buildPdfRow('Phone', profileData['phone1'] ?? ''),
                _buildPdfRow('Company Name', profileData['companyName'] ?? ''),
                _buildPdfRow('Designation', profileData['designation'] ?? ''),
                _buildPdfRow('Website', profileData['companyWebsite'] ?? ''),
                if (profileData['dob'] != null)
                  _buildPdfRow('DOB', _formatTimestamp(profileData['dob'])),
              ],
              pw.SizedBox(height: 30),
              pw.Text(
                'This document was generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    }
    return 'Invalid date';
  }

  pw.Widget _buildPdfRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text('$title:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  Future<File> _savePdfToDownloads(File tempFile, String userId) async {
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getTemporaryDirectory();
      }

      final fileName =
          'user_${userId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final finalFile = File(path.join(downloadsDir!.path, fileName));
      return await tempFile.copy(finalFile.path);
    } catch (e) {
      print('Error saving PDF to downloads: $e');
      return tempFile;
    }
  }

  Future<void> _downloadUserDetails(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        ),
      );

      final tempPdfFile = await _generatePdf(userData, userId);

      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      bool isGranted = statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true;

      File finalPdfFile = tempPdfFile;

      if (isGranted) {
        finalPdfFile = await _savePdfToDownloads(tempPdfFile, userId);
      }

      if (context.mounted) Navigator.of(context).pop();
      await OpenFile.open(finalPdfFile.path);
    } catch (e) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshUserList,
          )
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
              final isActive = userData['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: Icon(Icons.person, color: Colors.green),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(email)),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.green),
                        onPressed: () =>
                            _downloadUserDetails(context, userData, docId),
                        tooltip: 'Download user details',
                      ),
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
                            _toggleUserStatus(docId, isActive),
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
