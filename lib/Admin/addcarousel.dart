import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:image/image.dart' as img; // ✅ Import the image package

class AdminImageUploadPage extends StatefulWidget {
  const AdminImageUploadPage({super.key});

  @override
  _AdminImageUploadPageState createState() => _AdminImageUploadPageState();
}

class _AdminImageUploadPageState extends State<AdminImageUploadPage> {
  List<File?> images = List.filled(4, null);
  List<String?> imageUrls = List.filled(4, null);
  bool isUploading = false;
  String? errorMessage;

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchExistingImages();
  }

  Future<void> _fetchExistingImages() async {
    try {
      final doc =
          await _firestore.collection('carousel_images').doc('images').get();
      if (doc.exists) {
        final data = doc.data();
        final List<dynamic>? urls = data?['urls'];
        if (urls != null && urls.length == 4) {
          setState(() {
            imageUrls = urls.cast<String?>();
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching existing images: $e';
      });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final originalBytes = await imageFile.readAsBytes();

      // Decode and resize the image
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) throw Exception("Invalid image");

      img.Image resized =
          img.copyResize(image, width: 800); // resize width to 800px

      final resizedBytes = img.encodeJpg(resized); // encode back to JPEG

      final url = Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'TempApp';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        resizedBytes,
        filename: 'resized.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'] as String;
      } else {
        throw HttpException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading to Cloudinary: $e')),
      );
      return null;
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        images[index] = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImagesAndSaveUrls() async {
    setState(() {
      isUploading = true;
      errorMessage = null;
    });

    try {
      List<String?> updatedUrls = List.from(imageUrls);

      for (int i = 0; i < images.length; i++) {
        if (images[i] != null) {
          final url = await _uploadToCloudinary(images[i]!);
          if (url != null) {
            updatedUrls[i] = url;
          } else {
            throw Exception('Failed to upload image ${i + 1}');
          }
        }
      }

      await _firestore.collection('carousel_images').doc('images').set({
        'urls': updatedUrls,
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        isUploading = false;
        imageUrls = updatedUrls;
        images = List.filled(4, null); // Clear local image cache
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Images updated and URLs saved successfully!')),
        );
      });
    } catch (e) {
      setState(() {
        isUploading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
        backgroundColor: Colors.green,
        title: Text(
          'Admin: Update Carousel Images',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select or Update 4 Images for Carousel',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _pickImage(index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: images[index] != null
                          ? Image.file(images[index]!, fit: BoxFit.cover)
                          : imageUrls[index] != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrls[index]!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error,
                                          color: Colors.red),
                                )
                              : const Center(child: Text('Tap to select')),
                    ),
                  );
                },
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: isUploading ||
                      (images.every((img) => img == null) &&
                          imageUrls.any((url) => url == null))
                  ? null
                  : _uploadImagesAndSaveUrls,
              child: isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Update Images',
                      style: GoogleFonts.oswald(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
