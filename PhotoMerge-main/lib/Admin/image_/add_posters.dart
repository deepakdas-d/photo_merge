import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AddImagePage extends StatefulWidget {
  const AddImagePage({Key? key}) : super(key: key);

  @override
  State<AddImagePage> createState() => _AddImagePageState();
}

class _AddImagePageState extends State<AddImagePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<File> _selectedImages = [];
  bool _isUploading = false;
  String? _selectedCategory = null;
  String? _selectedSubcategory;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      List<File> resizedImages = [];
      for (var pickedFile in pickedFiles) {
        final resizedFile = await _resizeImage(File(pickedFile.path));
        if (resizedFile != null) {
          resizedImages.add(resizedFile);
        }
      }

      setState(() {
        _selectedImages.addAll(resizedImages);
      });
    }
  }

  // Function to resize image to exactly 941x1280 pixels
  Future<File?> _resizeImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      // Resize the image to 941x1280 pixels
      final resizedImage =
          // img.copyResize(originalImage, width: 941, height: 1280);
          img.copyResize(
        originalImage,
        width: 2480,
      );

      // Save the resized image
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedFile = File(targetPath);

      await resizedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 90));

      return resizedFile;
    } catch (e) {
      print('Error resizing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resizing image: $e')),
      );
      return null;
    }
  }

  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dlacr6mpw/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'BrandBuilder';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

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

  Future<void> _uploadImages() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images selected.')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category and subcategory.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (var i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final imageUrl = await _uploadToCloudinary(image);

        if (imageUrl != null) {
          await _firestore
              .collection('admin_images')
              .doc(currentUser.uid)
              .collection('images')
              .add({
            'image_url': imageUrl,
            'category': _selectedCategory,
            'subcategory': _selectedSubcategory,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to add images')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please wait for upload to complete.')),
          );
          return false; // Prevent back navigation during upload
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF00B6B0),
          title: Text(
            'Add Images',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          padding: const EdgeInsets.only(top: 30.0),
          color: Colors.white,
          child: _isUploading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Dropdown
                      StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('categories')
                              .where('createdBy', isEqualTo: currentUser.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            final categories = snapshot.data?.docs
                                    .map((doc) => doc['name'] as String)
                                    .toList() ??
                                [];

                            if (categories.isEmpty) {
                              return const Text(
                                'No categories available. Please add categories first.',
                              );
                            }

                            return WillPopScope(
                              onWillPop: () async {
                                if (_selectedCategory != null) {
                                  setState(() {
                                    _selectedCategory = null;
                                    _selectedSubcategory =
                                        null; // Reset subcategory too
                                  });
                                  return false; // Block navigation
                                }
                                return true; // Allow navigation
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey
                                      .shade400, // Set background color to white
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners with more curve
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(
                                          0.3), // Slightly stronger shadow
                                      spreadRadius: 3,
                                      blurRadius: 6,
                                      offset: Offset(0,
                                          5), // Position the shadow slightly more noticeable
                                    ),
                                  ],
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  hint: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            16.0), // Padding for hint text
                                    child: const Text(
                                      'Select Category',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16), // Bigger font size
                                    ),
                                  ),
                                  items: categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal:
                                                16.0), // More vertical space for items
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize:
                                                16, // Consistent and readable font size
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                      _selectedSubcategory =
                                          null; // Reset subcategory
                                    });
                                  },
                                  underline:
                                      Container(), // Remove the underline
                                  iconSize:
                                      30.0, // Make the dropdown icon bigger
                                  style: TextStyle(
                                      fontSize:
                                          16), // Adjust text style for readability
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical:
                                          10.0), // Padding for the dropdown button
                                ),
                              ),
                            );
                          }),
                      const SizedBox(height: 50),
                      // Subcategory Dropdown
                      StreamBuilder<DocumentSnapshot>(
                        stream: _selectedCategory != null
                            ? _firestore
                                .collection('categories')
                                .where('name', isEqualTo: _selectedCategory)
                                .where('createdBy', isEqualTo: currentUser.uid)
                                .snapshots()
                                .map((snapshot) => snapshot.docs.first)
                            : null,
                        builder: (context, snapshot) {
                          if (_selectedCategory == null ||
                              snapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          final subcategories = List<String>.from(
                              snapshot.data?['subcategories'] ?? []);
                          if (subcategories.isEmpty) {
                            return const Text(
                                'No subcategories available for this category.');
                          }
                          // if (_selectedSubcategory == null ||
                          //     !subcategories.contains(_selectedSubcategory)) { this caused the pre loading.
                          //   _selectedSubcategory = subcategories.first;
                          // }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey
                                  .shade400, // Set background color to white
                              borderRadius: BorderRadius.circular(
                                  8), // Add rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3), // Shadow position
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors
                                    .grey.shade400, // Light grey background
                                borderRadius: BorderRadius.circular(
                                    12), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedSubcategory,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    'Select Subcategory',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                items: subcategories.map((subcategory) {
                                  return DropdownMenuItem<String>(
                                    value: subcategory,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 16.0,
                                      ),
                                      child: Text(
                                        subcategory,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSubcategory = value;
                                  });
                                },
                                underline:
                                    Container(), // Removes the default underline
                                iconSize: 30.0,
                                style: const TextStyle(fontSize: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 10.0),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selected Images Preview with dimension info
                      if (_selectedImages.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Images (Resized to 941x1280)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            _selectedImages[index],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Pick Images',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B6B0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectedImages.isNotEmpty
                                ? _uploadImages
                                : null,
                            icon: const Icon(Icons.cloud_upload,
                                color: Colors.white),
                            label: const Text('Upload',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B6B0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
