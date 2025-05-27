import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/categorey.dart';
import 'package:photomerge/User/View/imagedetails.dart';
import 'package:photomerge/User/View/provider/authprovider.dart';
import 'package:photomerge/User/View/provider/carousalprovider.dart';
import 'package:photomerge/User/View/provider/categoryprovider.dart';
import 'package:photomerge/User/View/provider/recentimage_provider.dart';
import 'package:photomerge/User/View/provider/userprovider.dart';
import 'package:provider/provider.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final ScrollController _scrollController = ScrollController();
  //firebase
  final userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
//color
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);

  //userimage
  String? _userImageUrl;
  @override
  void initState() {
    super.initState();

    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserDataProvider>().fetchUserData(userId);
        context.read<CarouselProvider>().fetchCarouselImages();
        context.read<CategoriesProvider>().fetchCategories();
        context.read<RecentImagesProvider>().fetchRecentImages();
        _loadUserProfileImage();
      });
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfileImage() async {
    setState(() => _isLoading = true);

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      _showSnackBar('No user signed in', isError: true);
      return;
    }

    try {
      final profileDoc = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get();

      if (profileDoc.exists && mounted) {
        final profileData = profileDoc.data()!;
        print('Fetched user image URL: ${profileData['userImage']}');
        setState(() {
          _userImageUrl = profileData['userImage']; // store the image URL
        });
      }
    } catch (e) {
      _showSnackBar('Error loading profile picture: $e', isError: true);
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

  // Modern UI theme colors - matching original page
  static const Color primaryColor = Color(0xFF00A19A); // Teal main color
  static const Color secondaryColor = Color(0xFFF8FAFA); // Light background
  static const Color accentColor = Color(0xFF005F5C); // Darker teal
  static const Color cardColor = Colors.white; // White cards
  static const Color textColor = Color(0xFF212121); // Primary text
  static const Color subtitleColor = Color(0xFF757575); // Secondary text

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: secondaryColor,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.copyWith(
                headlineMedium: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                headlineSmall: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                titleMedium: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                bodyMedium: const TextStyle(fontSize: 14, color: textColor),
                bodySmall: const TextStyle(fontSize: 12, color: subtitleColor),
              ),
        ),
        iconTheme: const IconThemeData(color: accentColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: primaryColor),
        ),
       cardTheme: CardThemeData(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Exit App',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Are you sure you want to exit the app?',
                style: TextStyle(color: Colors.black87),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
            return false; // prevent default pop since SystemNavigator.pop() exits
          }
          return false;
        },
        child: Scaffold(
          backgroundColor: secondaryColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              "HOME",
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: primaryColor),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: GallerySearchDelegate(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined,
                    color: primaryColor),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
          drawer: userId != null ? _buildDrawer(context) : null,
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await context.read<UserDataProvider>().fetchUserData(userId);
              await context.read<CarouselProvider>().fetchCarouselImages();
              await context.read<CategoriesProvider>().fetchCategories();
              await context.read<RecentImagesProvider>().fetchRecentImages();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: buildCarousel(context)),
                SliverToBoxAdapter(child: buildWelcomeSection(context)),
                SliverToBoxAdapter(child: buildCategoriesSection(context)),
                SliverToBoxAdapter(child: buildRecentImagesSection(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/listimages');
            },
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildCarousel(BuildContext context) {
    return Consumer<CarouselProvider>(
      builder: (context, provider, child) {
        if (provider.imageUrls.isEmpty && provider.errorMessage == null) {
          return Container(
            height: 210,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (provider.errorMessage != null || provider.imageUrls.isEmpty) {
          return Container(
            height: 220,
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage ?? 'No images available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            CarouselSlider(
              key: const ValueKey('carousel'),
              options: CarouselOptions(
                height: 250,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.easeInOut,
                enlargeCenterPage: true,
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                onPageChanged: (index, reason) {
                  provider.setCurrentIndex(index);
                },
              ),
              items: provider.imageUrls.map((imageUrl) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.transparent,
                  child: AspectRatio(
                    aspectRatio: 1 / 4,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error_outline,
                              color: Colors.red, size: 32),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: provider.imageUrls.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.currentIndex == entry.key
                          ? Colors.white
                          : Colors.white.withAlpha(102),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildWelcomeSection(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text:
                            'Welcome${provider.userData?['firstName']?.isNotEmpty == true ? ", ${provider.userData!['firstName']}" : ""}',
                        style: GoogleFonts.oswald(
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Discover and organize your photos and videos',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 15),
                    ),
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: primaryColor.withOpacity(0.2), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCategoriesSection(BuildContext context) {
    return Consumer<CategoriesProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/Category');
                    },
                    child: Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.errorMessage != null)
                SizedBox(
                  height: 100,
                  child: Center(child: Text(provider.errorMessage!)),
                )
              else if (provider.categories.isEmpty)
                const SizedBox(
                  height: 100,
                  child: Center(child: Text('No categories available')),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final categoryData = provider.categories[index].data()
                          as Map<String, dynamic>;
                      final name = categoryData['name'] as String? ??
                          'Category ${index + 1}';
                      final imageUrl =
                          categoryData['image_url'] as String? ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Mycategory(categoryFilter: name),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: primaryColor,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.category,
                                            color: Colors.grey,
                                            size: 30,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRecentImagesSection(BuildContext context) {
    return Consumer<RecentImagesProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Images',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/listimages');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.errorMessage != null)
                const SizedBox(
                  height: 230,
                  child: Center(
                    child: Text(
                      'Error loading images',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              else if (provider.images.isEmpty)
                const SizedBox(
                  height: 230,
                  child: Center(child: Text('No images available')),
                )
              else
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.images.length,
                    itemBuilder: (context, index) {
                      final imageData =
                          provider.images[index].data() as Map<String, dynamic>;
                      final imageUrl = imageData['image_url'] as String? ?? '';
                      final category =
                          imageData['category'] as String? ?? 'Uncategorized';
                      final timestamp = imageData['timestamp'] as Timestamp?;
                      final timeAgo = timestamp != null
                          ? _getTimeAgo(timestamp.toDate())
                          : 'Unknown';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageDetailView(
                                photoId: provider.images[index].id,
                                photoUrl: imageUrl,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, provider, child) {
        return Drawer(
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            _userImageUrl != null && _userImageUrl!.isNotEmpty
                                ? NetworkImage(_userImageUrl!)
                                : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.userData?['firstName']?.isNotEmpty == true
                            ? provider.userData!['firstName']
                            : 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.userData?['email']?.isNotEmpty == true
                            ? provider.userData!['email']
                            : 'email@example.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.account_circle_outlined,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.photo_library_outlined,
                  title: 'My Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/listimages');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/Category');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.video_library_outlined,
                  title: 'My Videos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/listvedios');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'My Subscription',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/usersubscription');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/support');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(color: Colors.black87),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.black)),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                backgroundColor: primaryColor),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Log Out',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      final authProvider =
                          context.read<AuthProviders>(); // Safe now
                      await authProvider.logout();

                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}

class GallerySearchDelegate extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: _UserDashboardState.primaryColor,
        foregroundColor: _UserDashboardState.textColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: _UserDashboardState.textColor.withOpacity(0.6),
          fontWeight: FontWeight.normal,
        ),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: _UserDashboardState.textColor),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: _UserDashboardState.textColor),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: _UserDashboardState.secondaryColor,
        child: Center(
          child: Text(
            'Enter a search term',
            style: TextStyle(
              color: _UserDashboardState.textColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      color: _UserDashboardState.secondaryColor,
      child: Consumer<CategoriesProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                'Error loading suggestions',
                style: TextStyle(
                  color: _UserDashboardState.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }
          if (provider.categories.isEmpty) {
            return Center(
              child: Text(
                'No suggestions found',
                style: TextStyle(
                  color: _UserDashboardState.textColor.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }

          final searchQuery = query.toLowerCase();
          final categories = provider.categories.where((doc) {
            final name = (doc['name'] as String? ?? '').toLowerCase();
            return name.contains(searchQuery);
          }).toList();

          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No suggestions found',
                style: TextStyle(
                  color: _UserDashboardState.textColor.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categoryData =
                  categories[index].data() as Map<String, dynamic>;
              final name =
                  categoryData['name'] as String? ?? 'Category ${index + 1}';
              final imageUrl = categoryData['image_url'] as String?;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.category,
                              color: _UserDashboardState.accentColor,
                              size: 40,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.category,
                          color: _UserDashboardState.accentColor,
                          size: 40,
                        ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _UserDashboardState.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Mycategory(categoryFilter: name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
