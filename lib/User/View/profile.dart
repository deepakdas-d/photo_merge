import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photomerge/User/View/home.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Enhanced color palette
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF81C784);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1E293B);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFE2E8F0);
  static const Color errorColor = Color(0xFFB91C1C);
  static const Color successColor = Color(0xFF15803D);

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
  bool _isEditing = false;
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
      // Fetch from 'users' collection
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      // Fetch from 'user_profile' collection
      final profileDoc = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        // From 'users' collection
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        }

        // From 'user_profile' collection
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

        setState(() => _isEditing = false);
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
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isUserImage) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryColor),
              title: Text('Gallery', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isUserImage);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primaryColor),
              title: Text('Camera', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isUserImage);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File? imageFile, String? currentUrl) async {
    if (imageFile == null) return currentUrl;

    setState(() => _isSaving = true);
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'TempApp'
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

      final data = {
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

      await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        // _showSnackBar('Profile updated successfully');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserDashboard()),
        );
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
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: textColor,
              displayColor: textColor,
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: dividerColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          labelStyle: TextStyle(color: textSecondaryColor, fontSize: 14),
          floatingLabelStyle: TextStyle(color: primaryColor, fontSize: 14),
          errorStyle: const TextStyle(color: errorColor, fontSize: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.2),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      child: Scaffold(
        body: _isLoading
            ? const _LoadingIndicator()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 80),
                    sliver: SliverToBoxAdapter(
                      child: _isSaving
                          ? const _LoadingIndicator()
                          : Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildProfileHeader(),
                                  const SizedBox(height: 24),
                                  _buildInfoCard(
                                    'Personal Information',
                                    [
                                      _buildTextField(
                                        'First Name',
                                        Icons.person_outline,
                                        _firstNameController,
                                        semanticLabel: 'First Name',
                                      ),
                                      _buildTextField(
                                        'Last Name',
                                        Icons.person,
                                        _lastNameController,
                                        semanticLabel: 'Last Name',
                                      ),
                                      _buildTextField(
                                        'Email',
                                        Icons.email_outlined,
                                        _emailController,
                                        type: TextInputType.emailAddress,
                                        semanticLabel: 'Email Address',
                                        overrideEnabled:
                                            false, // make read-only
                                      ),
                                      _buildTextField(
                                        'Phone',
                                        Icons.phone_outlined,
                                        _phoneController,
                                        type: TextInputType.phone,
                                        semanticLabel: 'Phone Number',
                                        overrideEnabled:
                                            false, // make read-only
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildInfoCard(
                                    'Company Information',
                                    [
                                      _buildTextField(
                                        'Company Name',
                                        Icons.business_outlined,
                                        _companyNameController,
                                        semanticLabel: 'Company Name',
                                      ),
                                      _buildTextField(
                                        'Designation',
                                        Icons.work_outline,
                                        _designationController,
                                        semanticLabel: 'Designation',
                                      ),
                                      _buildTextField(
                                        'District',
                                        Icons.location_city,
                                        _districtController,
                                        semanticLabel: 'District',
                                      ),
                                      _buildTextField(
                                        'Branch',
                                        Icons.store,
                                        _branchController,
                                        semanticLabel: 'Branch',
                                      ),
                                      _buildTextField(
                                        'Website',
                                        Icons.link,
                                        _websiteController,
                                        type: TextInputType.url,
                                        semanticLabel: 'Company Website',
                                      ),
                                      _buildCompanyLogo(),
                                    ],
                                  ),
                                  if (_isEditing) _buildSaveButton(),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'My Profile',
        style: GoogleFonts.oswald(
          color: primaryColor,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!_isLoading && !_isSaving)
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit_outlined,
              color: primaryColor,
              size: 24,
            ),
            onPressed: _isEditing
                ? _updateUserData
                : () => setState(() => _isEditing = true),
            tooltip: _isEditing ? 'Save Profile' : 'Edit Profile',
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final fullName =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Semantics(
                label: 'Profile Image',
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: dividerColor.withOpacity(0.2),
                  backgroundImage: _userImage != null
                      ? FileImage(_userImage!)
                      : _userImageUrl?.isNotEmpty ?? false
                          ? NetworkImage(_userImageUrl!)
                          : null,
                  child: _userImage == null && (_userImageUrl?.isEmpty ?? true)
                      ? Icon(
                          Icons.person,
                          size: 56,
                          color: textSecondaryColor,
                        )
                      : null,
                ),
              ),
              if (_isEditing)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: GestureDetector(
                    onTap: () => _showImagePickerOptions(true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isEmpty ? 'Complete Your Profile' : fullName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text.isEmpty
                ? 'Add your email'
                : _emailController.text,
            style: TextStyle(
              fontSize: 15,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? semanticLabel,
    bool? overrideEnabled,
  }) {
    final isFieldEnabled = overrideEnabled ?? _isEditing;

    return Semantics(
      label: semanticLabel ?? label,
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isFieldEnabled,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          suffixIcon: isFieldEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: textSecondaryColor, size: 20),
                  onPressed: () => controller.clear(),
                )
              : null,
        ),
        validator: (value) {
          if (value?.trim().isEmpty ?? true) return '$label is required';

          if (type == TextInputType.emailAddress &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
            return 'Enter a valid email';
          }
          if (type == TextInputType.phone &&
              !RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value!)) {
            return 'Enter a valid phone number';
          }
          if (type == TextInputType.url &&
              !RegExp(r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w- .\/?%&=]*)?$')
                  .hasMatch(value!)) {
            return 'Enter a valid URL';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Logo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _isEditing ? () => _showImagePickerOptions(false) : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: dividerColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _companyLogo != null
                    ? Image.file(
                        _companyLogo!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      )
                    : _companyLogoUrl?.isNotEmpty ?? false
                        ? Image.network(
                            _companyLogoUrl!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                _buildLogoPlaceholder(),
                          )
                        : _buildLogoPlaceholder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.business,
          size: 40,
          color: textSecondaryColor.withOpacity(0.6),
        ),
        if (_isEditing)
          Text(
            'Add Logo',
            style: TextStyle(
              fontSize: 12,
              color: textSecondaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateUserData,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save Profile'),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _ProfilePageState.primaryColor,
        strokeWidth: 3,
      ),
    );
  }
}
