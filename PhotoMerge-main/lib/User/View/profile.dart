import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as flutterSecureStorage;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Color palette (unchanged)
  static const Color primaryColor = Color(0xFF00A19A);
  static const Color accentColor = Color(0xFF005F5C);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFE2E8F0);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _companyNameController;
  late TextEditingController _designationController;
  late TextEditingController _websiteController;
  late TextEditingController _districtController;
  late TextEditingController _branchController;

  // Image state
  File? _userImage;
  String? _userImageUrl;
  File? _companyLogo;
  String? _companyLogoUrl;

  // UI state
  bool _isLoading = true;
  bool _isEditing = true; // Start in edit mode for simplicity
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _companyNameController = TextEditingController();
    _designationController = TextEditingController();
    _websiteController = TextEditingController();
    _districtController = TextEditingController();
    _branchController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _designationController.dispose();
    _websiteController.dispose();
    _districtController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      _showSnackBar('No user signed in', isError: true);
      return;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final profileDoc = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        }

        if (profileDoc.exists) {
          final profileData = profileDoc.data()!;
          _firstNameController.text = profileData['firstName'] ?? '';
          _lastNameController.text = profileData['lastName'] ?? '';
          _companyNameController.text = profileData['companyName'] ?? '';
          _designationController.text = profileData['designation'] ?? '';
          _websiteController.text = profileData['companyWebsite'] ?? '';
          _districtController.text = profileData['district'] ?? '';
          _branchController.text = profileData['branch'] ?? '';
          _userImageUrl = profileData['userImage'];
          _companyLogoUrl = profileData['companyLogo'];
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isUserImage) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (isUserImage) {
            _userImage = File(pickedFile.path);
          } else {
            _companyLogo = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  void _showImagePickerOptions(bool isUserImage) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: cardColor,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_library, color: primaryColor),
            title: Text('Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery, isUserImage);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt, color: primaryColor),
            title: Text('Camera',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera, isUserImage);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(File? imageFile, String? currentUrl) async {
    if (imageFile == null) return currentUrl;

    setState(() => _isSaving = true);
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/dlacr6mpw/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'BrandBuilder'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response =
          await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData)['secure_url'];
      }
      throw Exception('Upload failed with status ${response.statusCode}');
    } catch (e) {
      _showSnackBar('Image upload failed: $e', isError: true);
      return currentUrl;
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      _showSnackBar('No user signed in', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      _userImageUrl = await _uploadImage(_userImage, _userImageUrl);
      _companyLogoUrl = await _uploadImage(_companyLogo, _companyLogoUrl);

      // Get current device ID
      final String deviceId =
          await _getDeviceId(); // Add _getDeviceId method (see below)

      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'designation': _designationController.text.trim(),
        'companyWebsite': _websiteController.text.trim(),
        'district': _districtController.text.trim(),
        'branch': _branchController.text.trim(),
        'userImage': _userImageUrl ?? '',
        'companyLogo': _companyLogoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if all required fields are non-empty
      bool isProfileComplete = _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _companyNameController.text.trim().isNotEmpty &&
          _designationController.text.trim().isNotEmpty &&
          _districtController.text.trim().isNotEmpty &&
          _branchController.text.trim().isNotEmpty &&
          (_userImageUrl?.isNotEmpty ?? false);

      // Update user_profile collection
      await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .set(profileData, SetOptions(merge: true));

      // Update users collection with profile_status and preserve deviceId
      await _firestore.collection('users').doc(currentUser.uid).set({
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'isActive': true,
        'role': 'user',
        'profile_status': isProfileComplete,
        'deviceId': deviceId, // Preserve deviceId
        'isLoggedIn': true, // Preserve login status
      }, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('Profile updated successfully');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => UserDashboard()));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light()
              .textTheme
              .apply(bodyColor: textColor, displayColor: textColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          labelStyle:
              GoogleFonts.poppins(color: textSecondaryColor, fontSize: 14),
          floatingLabelStyle:
              GoogleFonts.poppins(color: primaryColor, fontSize: 14),
          errorStyle: GoogleFonts.poppins(color: errorColor, fontSize: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        colorScheme: ColorScheme.light(
            primary: primaryColor, secondary: accentColor, error: errorColor),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text('Complete Your Profile',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const _LoadingIndicator()
            : _isSaving
                ? const _LoadingIndicator()
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildProfileImageSection(),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Personal Information'),
                        _buildTextField(
                            'First Name', Icons.person, _firstNameController),
                        _buildTextField(
                            'Last Name', Icons.person, _lastNameController),
                        _buildTextField('Email', Icons.email, _emailController,
                            type: TextInputType.emailAddress,
                            overrideEnabled: false),
                        _buildTextField('Phone', Icons.phone, _phoneController,
                            type: TextInputType.phone, overrideEnabled: false),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Company Information'),
                        _buildCompanyLogoSection(),
                        _buildTextField('Company Name', Icons.business,
                            _companyNameController),
                        _buildTextField(
                            'Designation', Icons.work, _designationController),
                        _buildTextField('District', Icons.location_city,
                            _districtController),
                        _buildTextField(
                            'Branch', Icons.store, _branchController),
                        _buildweb(
                          'Website',
                          Icons.link,
                          _websiteController,
                          type: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _updateUserData,
                          child: const Text('Save Profile'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(true),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: dividerColor,
                  backgroundImage: _userImage != null
                      ? FileImage(_userImage!)
                      : _userImageUrl?.isNotEmpty ?? false
                          ? NetworkImage(_userImageUrl!)
                          : null,
                  child: _userImage == null && (_userImageUrl?.isEmpty ?? true)
                      ? Icon(Icons.person, size: 50, color: textSecondaryColor)
                      : null,
                ),
                if (_userImage != null || (_userImageUrl?.isNotEmpty ?? false))
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _userImage = null;
                          _userImageUrl = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add profile picture',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    return GestureDetector(
      onTap: () => _showImagePickerOptions(false),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dividerColor),
                  ),
                  child: _companyLogo != null
                      ? Image.file(_companyLogo!, fit: BoxFit.cover)
                      : _companyLogoUrl?.isNotEmpty ?? false
                          ? Image.network(_companyLogoUrl!, fit: BoxFit.cover)
                          : Icon(Icons.business,
                              size: 40, color: textSecondaryColor),
                ),
                if (_companyLogo != null ||
                    (_companyLogoUrl?.isNotEmpty ?? false))
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _companyLogo = null;
                          _companyLogoUrl = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add company logo',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildweb(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              color: Color(0xFF00A19A), strokeWidth: 3),
          const SizedBox(height: 16),
          Text('Loading...',
              style:
                  GoogleFonts.poppins(fontSize: 16, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
