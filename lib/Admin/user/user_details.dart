import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;

class UserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Map<String, dynamic> userData;

  const UserDetailsPage({
    required this.profileData,
    required this.userData,
    Key? key,
  }) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Future<File> _generatePdf(
    Map<String, dynamic> userData,
    Map<String, dynamic> profileData,
    String userId,
  ) async {
    final pdf = pw.Document();

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
                  'First Name', profileData['firstName'] ?? 'Not provided'),
              _buildPdfRow(
                  'Last Name', profileData['lastName'] ?? 'Not provided'),
              _buildPdfRow('Email', userData['email'] ?? 'Not provided'),
              _buildPdfRow('Phone', profileData['phone1'] ?? 'Not provided'),
              _buildPdfRow('Role', userData['role'] ?? 'Not provided'),
              _buildPdfRow(
                  'Company', profileData['companyName'] ?? 'Not provided'),
              _buildPdfRow(
                  'Designation', profileData['designation'] ?? 'Not provided'),
              _buildPdfRow(
                  'Website', profileData['companyWebsite'] ?? 'Not provided'),
              _buildPdfRow('Created', _formatTimestamp(userData['createdAt'])),
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
    final displayName = (profileData['firstName'] ?? 'user').toString().trim();
    final safeName = displayName.replaceAll(RegExp(r'\s+'), '_');
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

      // ✅ FIXED: Corrected method call with profileData
      final tempPdfFile =
          await _generatePdf(userData, widget.profileData, userId);

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
        finalPdfFile = await _savePdfToDownloads(tempPdfFile, userId);
        await tempPdfFile.delete();
        print('PDF saved to: ${finalPdfFile.path}');
      } else {
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

      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      final result = await OpenFile.open(finalPdfFile.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: ${result.message}')),
        );
      }

      if (isStorageGranted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('PDF saved to Downloads folder: ${finalPdfFile.path}'),
          ),
        );
      }
    } catch (e) {
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
        title: Text(
          'User Details',
          style: GoogleFonts.oswald(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF00B6B0),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('First Name',
                widget.profileData['firstName'] ?? 'N/A', Icons.person),
            SizedBox(height: 15),
            _buildProfileRow('Last Name',
                widget.profileData['lastName'] ?? 'N/A', Icons.person_outline),
            SizedBox(height: 15),
            _buildProfileRow('Email', widget.profileData['email'], Icons.email),
            SizedBox(height: 15),
            _buildProfileRow(
                'Phone', widget.profileData['phone'] ?? 'N/A', Icons.phone),
            SizedBox(height: 15),
            _buildProfileRow('Role', widget.userData['role'], Icons.work),
            SizedBox(height: 15),
            _buildProfileRow('Company',
                widget.profileData['companyName'] ?? 'N/A', Icons.business),
            SizedBox(height: 15),
            _buildProfileRow('Designation',
                widget.profileData['designation'] ?? 'N/A', Icons.title),
            SizedBox(height: 15),
            _buildProfileRow('Website',
                widget.profileData['companyWebsite'] ?? 'N/A', Icons.language),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final userId = widget.userData['uid'] ?? 'unknown_user';
                  _downloadUserDetails(context, widget.userData, userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  "Download",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF00B6B0), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$label: $value',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4), // space before underline
          Divider(
            color: Colors.black, // underline color
            thickness: 1, // thickness of underline
            height: 1,
          ),
        ],
      ),
    );
  }
}
