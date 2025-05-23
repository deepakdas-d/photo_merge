import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/listimages.dart';
import 'package:photomerge/User/View/provider/image_details_provider.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ImageDetailView extends StatelessWidget {
  final String photoId;
  final String photoUrl;

  const ImageDetailView(
      {Key? key, required this.photoId, required this.photoUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageDetailViewModel(photoUrl),
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
          leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ListImages()),
              );
            },
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00A19A)),
          ),
        ),
        body: Consumer<ImageDetailViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading, please wait...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.error != null) {
              return Center(child: Text('Error: ${viewModel.error}'));
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhotoCard(context, viewModel, photoId, photoUrl),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, ImageDetailViewModel viewModel,
      String photoId, String photoUrl) {
    final GlobalKey cardKey = GlobalKey();
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
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 1200,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.grey[300]),
                        ),
                        errorWidget: (context, url, error) {
                          print('Image load error for $url: $error');
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error,
                                  size: 48, color: Colors.red),
                            ),
                          );
                        },
                      ),
                      Positioned.fill(
                        child: Center(
                          child: CustomPaint(
                            painter:
                                WatermarkPainter(userData: viewModel.userData),
                          ),
                        ),
                      ),
                      Positioned(
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
                      ),
                    ],
                  ),
                ),
                if (viewModel.userData != null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(color: viewModel.backgroundColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
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
                                child: viewModel.userData!['userImage'] !=
                                            null &&
                                        viewModel.userData!['userImage']
                                            .toString()
                                            .isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl:
                                            viewModel.userData!['userImage'],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.white.withOpacity(0.2),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 1.5),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.white.withOpacity(0.2),
                                          child: const Icon(Icons.person,
                                              size: 28, color: Colors.white),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.white.withOpacity(0.2),
                                        child: const Icon(Icons.person,
                                            size: 28, color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${viewModel.userData!['firstName'] ?? ''} ${viewModel.userData!['lastName'] ?? ''}'
                                            .trim()
                                            .isNotEmpty
                                        ? '${viewModel.userData!['firstName'] ?? ''} ${viewModel.userData!['lastName'] ?? ''}'
                                            .trim()
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
                                  Text(
                                    viewModel.userData!['designation'] ??
                                        'No designation',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    viewModel.userData!['phone'] ?? 'No Number',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    viewModel.userData!['email'] ?? 'No email',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    viewModel.userData!['companyWebsite'] ??
                                        'No Website',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (viewModel.userData!['companyLogo'] != null &&
                                viewModel.userData!['companyLogo']
                                    .toString()
                                    .isNotEmpty)
                              Container(
                                width: 55,
                                height: 55,
                                decoration:
                                    const BoxDecoration(shape: BoxShape.circle),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        viewModel.userData!['companyLogo'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.business,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
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
                  child: TextButton.icon(
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => viewModel.captureAndSaveImage(
                        photoId, photoUrl, cardKey, context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    icon:
                        const Icon(Icons.share, size: 18, color: Colors.white),
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
                        photoId, photoUrl, cardKey, context),
                  ),
                ),
              ],
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
