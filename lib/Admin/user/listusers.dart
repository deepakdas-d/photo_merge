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

  Future<void> _setUserStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': newStatus,
      });
    } catch (e) {
      print('Error setting user status: $e');
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
              _buildPdfRow(
                'Name',
                '${profileData?['firstName'] ?? ''} ${profileData?['lastName'] ?? ''}'
                        .trim()
                        .isNotEmpty
                    ? '${profileData?['firstName'] ?? ''} ${profileData?['lastName'] ?? ''}'
                        .trim()
                    : 'Not provided',
              ),
              _buildPdfRow('Email', userData['email'] ?? 'Not provided'),
              _buildPdfRow('Phone', userData['phone'] ?? 'Not provided'),
              _buildPdfRow('Role', userData['role'] ?? 'Not provided'),
              if (profileData != null) ...[
                _buildPdfRow(
                    'Created', _formatTimestamp(userData['createdAt'])),
                _buildPdfRow(
                    'Company', profileData['companyName'] ?? 'Not provided'),
                _buildPdfRow('Designation',
                    profileData['designation'] ?? 'Not provided'),
                _buildPdfRow(
                    'Website', profileData['companyWebsite'] ?? 'Not provided'),
              ],
              pw.SizedBox(height: 30),
              pw.Text(
                'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final displayName = (userData['firstName'] ?? 'user').toString().trim();
    final safeName = displayName.replaceAll(
        RegExp(r'\s+'), '_'); // Replace spaces with underscores
    final fileName = '${safeName}_details.pdf';
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
              width: 120,
              child: pw.Text('$title:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
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
      // Show loading dialog
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

      // Generate the PDF
      final tempPdfFile = await _generatePdf(userData, userId);

      // Request permissions
      final statuses = await [
        Permission.storage,
        if (Platform.isAndroid) Permission.manageExternalStorage,
      ].request();

      final isStorageGranted = statuses[Permission.storage]?.isGranted ==
              true ||
          (Platform.isAndroid &&
              statuses[Permission.manageExternalStorage]?.isGranted == true);

      File finalPdfFile;

      if (isStorageGranted) {
        // Save to Downloads
        finalPdfFile = await _savePdfToDownloads(tempPdfFile, userId);
        await tempPdfFile.delete(); // Clean up temp file
        print('PDF saved to: ${finalPdfFile.path}');
      } else {
        // Permission denied, use temp file
        finalPdfFile = tempPdfFile;
        print('Storage permission denied. Using temporary file.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Storage permission denied. PDF will not be saved to Downloads.'),
            ),
          );
        }
      }

      // Close the loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Open the PDF
      final result = await OpenFile.open(finalPdfFile.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: ${result.message}')),
        );
      }

      // Notify user of save success
      if (isStorageGranted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('PDF saved to Downloads folder: ${finalPdfFile.path}'),
          ),
        );
      }
    } catch (e) {
      // Handle errors
      print('Error generating or saving PDF: $e');
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating or saving PDF: $e')),
        );
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

          // final users = snapshot.data!.docs; // this is for all the account

          final users = snapshot.data!.docs.where((doc) {
            final data =
                doc.data() as Map<String, dynamic>; //this for admin filtering
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
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.green),
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
                            _setUserStatus(docId, newValue),
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
