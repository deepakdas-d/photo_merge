import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:url_launcher/url_launcher.dart';

class AllVideosPage extends StatefulWidget {
  const AllVideosPage({super.key});

  @override
  State<AllVideosPage> createState() => _AllVideosPageState();
}

class _AllVideosPageState extends State<AllVideosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define theme colors
  final Color _primaryColor = Color(0xFF4CAF50);
  final Color _backgroundColor = Colors.white;
  final Color _shadowColor = Colors.black12;

  // Define standard spacing
  final double _standardPadding = 16.0;
  final double _smallPadding = 8.0;
  final double _cardBorderRadius = 12.0; // Slightly smaller for compactness

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDashboard(),
                ));
          },
          icon: Icon(
            Icons.arrow_back,
          ),
          color: Colors.green,
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Video Gallery',
          style: GoogleFonts.oswald(
            color: Colors.green,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildVideosSection(),
      ),
    );
  }

  Widget _buildVideosSection() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async {
        setState(() {}); // Simple refresh functionality
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(_standardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
              const SizedBox(height: 8),
              _buildVideosGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('videos')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyStateWidget();
          }

          final videos = snapshot.data!.docs;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getGridCrossAxisCount(context),
              childAspectRatio: 0.9, // Square cards for balance
              crossAxisSpacing: _smallPadding,
              mainAxisSpacing: _standardPadding,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final videoData = videos[index].data() as Map<String, dynamic>;
              return VideoCard(
                videoData: videoData,
                videoId: videos[index].id,
                primaryColor: _primaryColor,
                borderRadius: _cardBorderRadius,
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to determine grid columns based on screen width
  int _getGridCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 900) return 4; // Large screens
    if (width > 600) return 3; // Medium screens
    if (width > 400) return 2; // Small screens
    return 1; // Extra small screens
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            SizedBox(height: 8),
            Text(
              'Error loading videos',
              style: TextStyle(color: Colors.redAccent),
            ),
            SizedBox(height: 4),
            Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.videocam_off, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text(
              'No videos available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final Map<String, dynamic> videoData;
  final String videoId;
  final Color primaryColor;
  final double borderRadius;

  const VideoCard({
    super.key,
    required this.videoData,
    required this.videoId,
    required this.primaryColor,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final videoUrl = videoData['url'] as String? ?? '';
    final title = videoData['name'] as String? ?? 'Untitled';
    final timestamp = videoData['timestamp'] as Timestamp?;
    final timeAgo =
        timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Unknown';
    final youtubeId = _extractYouTubeId(videoUrl);

    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: 2, // Reduced elevation for a flatter look
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => _launchVideo(context, videoUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with play button overlay
              ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(borderRadius)),
                child: AspectRatio(
                  aspectRatio: 16 / 14, // Standard YouTube thumbnail ratio
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildThumbnail(youtubeId),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),

                      // Play button
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6), // Smaller padding
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.9),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24, // Smaller icon
                          ),
                        ),
                      ),

                      // Time ago indicator
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeAgo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8, // Smaller font
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Video details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8), // Reduced padding
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, // Smaller font
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String youtubeId) {
    if (youtubeId.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg',
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child:
                Icon(Icons.broken_image_rounded, color: Colors.grey, size: 30),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.grey, size: 30),
        ),
      );
    }
  }

  Future<void> _launchVideo(BuildContext context, String videoUrl) async {
    try {
      final uri = Uri.parse(videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, 'Could not open video link');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Invalid video link');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years${years == 1 ? 'y' : 'y'} ago';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months${months == 1 ? 'm' : 'm'} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  String _extractYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'] ?? '';
      }
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
