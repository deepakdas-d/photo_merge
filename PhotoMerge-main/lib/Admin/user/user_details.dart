import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
      final fileName =
          'user_${userId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (Platform.isAndroid) {
        // Primary approach: Try the standard Downloads directory
        downloadsDir = Directory('/storage/emulated/0/Download');

        // Check if directory exists and is accessible
        if (!await downloadsDir.exists() ||
            !(await _canWriteToDirectory(downloadsDir))) {
          // Alternative approach: Use External Storage Directory as fallback
          downloadsDir = await getExternalStorageDirectory();

          // If still not accessible, try alternative external directories
          if (downloadsDir == null ||
              !(await _canWriteToDirectory(downloadsDir))) {
            final externalDirs = await getExternalStorageDirectories();
            if (externalDirs != null && externalDirs.isNotEmpty) {
              downloadsDir = externalDirs.first;
            }
          }
        }

        // As last resort, use app's directory
        if (downloadsDir == null ||
            !(await _canWriteToDirectory(downloadsDir))) {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // On iOS, save to app's Documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        // Fallback for other platforms
        downloadsDir = await getTemporaryDirectory();
      }

      // Ensure the directory exists
      if (!await downloadsDir!.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final finalFile = File(path.join(downloadsDir.path, fileName));

      // Copy the temp file to the final location
      return await tempFile.copy(finalFile.path);
    } catch (e) {
      print('Error saving PDF to downloads: $e');
      return tempFile; // Return the original file if the operation fails
    }
  }

// Helper method to check if a directory is writable
  Future<bool> _canWriteToDirectory(Directory directory) async {
    try {
      // Try to create a temporary file in the directory
      final testFile = File(
          '${directory.path}/write_test_${DateTime.now().millisecondsSinceEpoch}.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      print('Directory is not writable: ${directory.path}, Error: $e');
      return false;
    }
  }

  Future<void> _downloadUserDetails(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    // Store the context at the beginning of the function
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        ),
      );

      // Generate PDF
      final tempPdfFile =
          await _generatePdf(userData, widget.profileData, userId);

      // Check Android version for appropriate permission request
      bool isAndroid13OrAbove = false;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;
      }

      // Request appropriate permissions based on platform and version
      bool permissionGranted = false;

      if (Platform.isAndroid) {
        if (isAndroid13OrAbove) {
          // For Android 13+ (API 33+), we need different permissions
          final status = await Permission.photos.request();
          permissionGranted = status.isGranted;
        } else {
          // For Android 12 and below
          final statuses = await [
            Permission.storage,
            Permission.manageExternalStorage,
          ].request();

          permissionGranted = statuses[Permission.storage]?.isGranted == true ||
              statuses[Permission.manageExternalStorage]?.isGranted == true;
        }
      } else if (Platform.isIOS) {
        // iOS doesn't need explicit permission for app documents directory
        permissionGranted = true;
      }

      File finalPdfFile;

      if (permissionGranted) {
        finalPdfFile = await _savePdfToDownloads(tempPdfFile, userId);
        await tempPdfFile.delete();
        print('PDF saved to: ${finalPdfFile.path}');

        // Show success message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                'PDF saved successfully to: ${path.basename(finalPdfFile.path)}'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        finalPdfFile = tempPdfFile;
        print('Storage permission denied. Using temporary file.');

        // Show permission denied message
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Storage permission denied. PDF will be opened but not saved to Downloads.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Dismiss the loading dialog if navigator is still valid
      if (navigator.canPop()) {
        navigator.pop();
      }

      // Open the PDF file
      final result = await OpenFile.open(finalPdfFile.path);
      if (result.type != ResultType.done) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error opening PDF: ${result.message}')),
        );
      }
    } catch (e) {
      print('Error generating or saving PDF: $e');
      // Dismiss the loading dialog if navigator is still valid
      if (navigator.canPop()) {
        navigator.pop();
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating or saving PDF: $e')),
      );
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
