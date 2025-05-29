import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:photomerge/User/View/provider/image_details_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

class ImageDetailView extends StatefulWidget {
  final String photoId;
  final String photoUrl;

  const ImageDetailView({
    Key? key,
    required this.photoId,
    required this.photoUrl,
  }) : super(key: key);

  @override
  State<ImageDetailView> createState() => _ImageDetailViewState();
}

class _ImageDetailViewState extends State<ImageDetailView> {
  final GlobalKey cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NoScreenshot.instance.screenshotOff();
  }

  @override
  void dispose() {
    NoScreenshot.instance.screenshotOn();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageDetailViewModel(widget.photoUrl),
      child: Consumer<ImageDetailViewModel>(
        builder: (context, viewModel, _) {
          return WillPopScope(
            onWillPop: () async {
              if (viewModel.isLoadingforbutton) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please wait, download in progress...'),
                  ),
                );
                return false;
              }
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text(
                  'Image Details',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00A19A),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                automaticallyImplyLeading: false,
                leading: viewModel.isLoadingforbutton
                    ? const SizedBox.shrink() // hide the back button
                    : IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back,
                            color: Color(0xFF00A19A)),
                      ),
              ),
              body: viewModel.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  : viewModel.error != null
                      ? Center(child: Text('Error: ${viewModel.error}'))
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildPhotoCard(context, viewModel),
                          ),
                        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, ImageDetailViewModel viewModel) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          RepaintBoundary(
            key: cardKey,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.photoUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 1200,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.grey[300]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child:
                                Icon(Icons.error, size: 48, color: Colors.red),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: CustomPaint(
                            painter:
                                WatermarkPainter(userData: viewModel.userData),
                          ),
                        ),
                      ),
                      _buildGradientOverlay(viewModel),
                    ],
                  ),
                ),
                if (viewModel.userData != null) _buildUserInfo(viewModel),
              ],
            ),
          ),
          _buildActions(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay(ImageDetailViewModel viewModel) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              viewModel.backgroundColor.withOpacity(0.1),
              viewModel.backgroundColor.withOpacity(0.3),
              viewModel.backgroundColor.withOpacity(0.5),
              viewModel.backgroundColor.withOpacity(0.7),
              viewModel.backgroundColor.withOpacity(0.9),
              viewModel.backgroundColor,
            ],
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(ImageDetailViewModel viewModel) {
    final user = viewModel.userData!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: viewModel.backgroundColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(user),
          const SizedBox(width: 6),
          Expanded(child: _buildUserTextDetails(user)),
          if (user['companyLogo'] != null &&
              user['companyLogo'].toString().isNotEmpty)
            _buildCompanyLogo(user),
        ],
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> user) {
    return Container(
      width: 82,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: user['userImage'] != null &&
                user['userImage'].toString().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: user['userImage'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white.withOpacity(0.2),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 1.5)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.white.withOpacity(0.2),
                  child:
                      const Icon(Icons.person, size: 28, color: Colors.white),
                ),
              )
            : Container(
                color: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, size: 28, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildUserTextDetails(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                  .trim()
                  .isNotEmpty
              ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
              : 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Color.fromARGB(80, 0, 0, 0),
              ),
            ],
          ),
        ),
        Text(user['designation'] ?? 'No designation',
            style: const TextStyle(fontSize: 11, color: Colors.white)),
        Text(user['phone'] ?? 'No Number',
            style: const TextStyle(fontSize: 11, color: Colors.white)),
        Text(user['email'] ?? 'No email',
            style: const TextStyle(fontSize: 10, color: Colors.white)),
        Text(user['companyWebsite'] ?? 'No Website',
            style: const TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }

  Widget _buildCompanyLogo(Map<String, dynamic> user) {
    return Container(
      width: 55,
      height: 55,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: user['companyLogo'],
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white54),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.business, size: 20, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ImageDetailViewModel viewModel) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: viewModel.isLoadingforbutton
                ? Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: viewModel.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.download,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Download',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: viewModel.backgroundColor,
                      minimumSize: const Size(double.infinity, 44),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      viewModel.setLoadingforbutton(true);
                      await viewModel.captureAndSaveImage(
                        widget.photoId,
                        widget.photoUrl,
                        cardKey,
                        context,
                        onStart: () => viewModel.setLoadingforbutton(true),
                        onComplete: () => viewModel.setLoadingforbutton(false),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.share, size: 18, color: Colors.white),
              label: const Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: viewModel.backgroundColor,
                minimumSize: const Size(double.infinity, 44),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => viewModel.shareImage(
                  widget.photoId, widget.photoUrl, cardKey, context),
            ),
          ),
        ],
      ),
    );
  }
}

// WatermarkPainter remains unchanged
class WatermarkPainter extends CustomPainter {
  final Map<String, dynamic>? userData;

  WatermarkPainter({this.userData});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: userData != null &&
                    '${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}'
                        .trim()
                        .isNotEmpty
                ? '${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}'
                    .trim()
                : 'Unknown User',
          ),
          const TextSpan(text: ' | '),
          TextSpan(
            text: userData?['phone'] ?? '',
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    final offset = Offset((size.width - textPainter.width) / 2, 8);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
