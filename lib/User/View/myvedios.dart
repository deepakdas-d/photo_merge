import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:photomerge/User/View/home.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AllVideosPage extends StatefulWidget {
  const AllVideosPage({super.key});

  @override
  State<AllVideosPage> createState() => _AllVideosPageState();
}

class _AllVideosPageState extends State<AllVideosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  // Theme colors and spacing
  final Color _primaryColor = const Color(0xFF4CAF50);
  final Color _backgroundColor = Colors.white;
  final double _standardPadding = 16.0;
  final double _cardBorderRadius = 20.0;

  // Categories matching AddVediourl
  final List<String> _categories = [
    'All',
    'Tutorial',
    'Entertainment',
    'Vlog',
    'Gaming',
    'Music',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 28),
          splashRadius: 24,
          tooltip: 'Back',
        ),
        title: AnimatedOpacity(
          opacity: _isSearchVisible ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            'Video Gallery',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search_rounded,
              color: Colors.white,
            ),
            splashRadius: 24,
            tooltip: _isSearchVisible ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            splashRadius: 24,
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isSearchVisible ? 60.0 : 0.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchVisible ? 60.0 : 0.0,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child:
                _isSearchVisible ? _buildSearchBar() : const SizedBox.shrink(),
          ),
        ),
      ),
      body: SafeArea(
        child: _buildVideosSection(),
      ),
    );
  }

  Widget _buildVideosSection() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(_standardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryChips(),
              const SizedBox(height: 20),
              _buildVideosGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search videos...',
          hintStyle:
              GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 16),
          prefixIcon:
              Icon(Icons.search_rounded, color: _primaryColor, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.grey.shade500, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: _primaryColor,
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideosGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .limit(20)
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

        final videos = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final category = data['category']?.toString() ?? '';
          final matchesSearch = name.contains(_searchQuery.toLowerCase());
          final matchesCategory =
              _selectedCategory == 'All' || category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (videos.isEmpty) {
          return _buildNoResultsWidget();
        }

        return AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getGridCrossAxisCount(context),
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final videoData = videos[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 400),
                columnCount: _getGridCrossAxisCount(context),
                child: ScaleAnimation(
                  scale: 0.8,
                  child: FadeInAnimation(
                    child: VideoCard(
                      videoData: videoData,
                      videoId: videos[index].id,
                      primaryColor: _primaryColor,
                      borderRadius: _cardBorderRadius,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() {}),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(color: _primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No videos available',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some videos to get started!',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Clear Search',
                style: GoogleFonts.poppins(color: _primaryColor),
              ),
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
    final category = videoData['category'] as String? ?? 'Uncategorized';
    final timestamp = videoData['timestamp'] as Timestamp?;
    final timeAgo =
        timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Unknown';
    final youtubeId = _extractYouTubeId(videoUrl);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            if (youtubeId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    videoId: youtubeId,
                    title: title,
                  ),
                ),
              );
            } else {
              _showErrorSnackBar(context, 'Invalid YouTube video link');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(borderRadius)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildThumbnail(youtubeId),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(borderRadius)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child:
                Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 36),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
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

// Video player screen implementation
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  YoutubePlayerValue? _playerValue;
  String _currentQuality = 'auto';
  List<String> _availableQualities = [
    'auto',
    '144p',
    '240p',
    '360p',
    '480p',
    '720p',
    '1080p'
  ];

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false,
      ),
    );

    // Listen to player value changes to update our UI
    _controller.addListener(_onPlayerValueChange);

    // Update quality options based on available formats
    // Note: YouTube API limitations mean we can only toggle between HD and standard quality
    _availableQualities = ['auto', '360p', '720p'];
  }

  void _onPlayerValueChange() {
    if (!mounted) return;
    setState(() {
      _playerValue = _controller.value;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerValueChange);
    _controller.dispose();
    super.dispose();
  }

  void _skipBackward() {
    final currentPosition = _controller.value.position.inSeconds;
    _controller.seekTo(Duration(seconds: currentPosition - 10));
  }

  void _skipForward() {
    final currentPosition = _controller.value.position.inSeconds;
    _controller.seekTo(Duration(seconds: currentPosition + 10));
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  void _changeQuality(String quality) {
    // Save current position before changing quality
    final currentPosition = _controller.value.position;

    // Update controller with new quality setting
    if (quality == 'auto') {
      // For auto, use default quality
      _controller.updateValue(
        _controller.value.copyWith(
          playerState: PlayerState.unknown,
        ),
      );
      _controller.reload();
    } else if (quality == '720p') {
      // For HD quality, recreate the controller with forceHD flag
      _controller.dispose();
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          forceHD: true,
        ),
      );
      _controller.addListener(_onPlayerValueChange);
      // Seek to previous position
      _controller.seekTo(currentPosition);
    } else {
      // For other qualities, recreate controller without forceHD
      _controller.dispose();
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          forceHD: false,
        ),
      );
      _controller.addListener(_onPlayerValueChange);
      // Seek to previous position
      _controller.seekTo(currentPosition);
    }

    setState(() {
      _currentQuality = quality;
    });

    // Close the quality selection menu
    Navigator.pop(context);
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Quality',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableQualities.length,
                  itemBuilder: (context, index) {
                    final quality = _availableQualities[index];
                    return ListTile(
                      title: Text(quality),
                      trailing: _currentQuality == quality
                          ? Icon(Icons.check, color: Color(0xFF4CAF50))
                          : null,
                      onTap: () => _changeQuality(quality),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Force portrait orientation when navigating back
          if (_isFullScreen) {
            // If in fullscreen, exit fullscreen first
            _controller.toggleFullScreenMode();
            return false; // Prevent back navigation, just exit fullscreen
          } else {
            // Set to portrait mode
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp]);
            return true; // Allow back navigation
          }
        },
        child: YoutubePlayerBuilder(
          onExitFullScreen: () {
            // Set to portrait mode when exiting fullscreen
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp]);
            setState(() {
              _isFullScreen = false;
            });
          },
          onEnterFullScreen: () {
            // Allow landscape orientations when entering fullscreen
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            setState(() {
              _isFullScreen = true;
            });
          },
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF4CAF50),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFF4CAF50),
              handleColor: Color(0xFF4CAF50),
            ),
            onReady: () {
              // Player is ready
            },
            bottomActions: [
              // Custom bottom controls

              CurrentPosition(),
              ProgressBar(
                isExpanded: true,
                colors: const ProgressBarColors(
                  playedColor: Color(0xFF4CAF50),
                  handleColor: Color(0xFF4CAF50),
                ),
              ),
              RemainingDuration(),
              // Add quality selector button
              IconButton(
                  onPressed: _skipForward,
                  icon: Icon(Icons.replay_10, color: Colors.white)),
              IconButton(
                  onPressed: _skipBackward,
                  icon: Icon(Icons.forward_10, color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _showQualitySelector,
              ),
              FullScreenButton(),
            ],
          ),
          builder: (context, player) {
            return Scaffold(
              appBar: _isFullScreen
                  ? null
                  : AppBar(
                      backgroundColor: Colors.white,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: const Color(0xFF4CAF50),
                        onPressed: () {
                          // Set to portrait mode before popping
                          SystemChrome.setPreferredOrientations(
                              [DeviceOrientation.portraitUp]);
                          Navigator.pop(context);
                        },
                      ),
                      title: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4CAF50),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      elevation: 0,
                    ),
              body: Column(
                children: [
                  // YouTube Player
                  player,

                  // Video information
                  if (!_isFullScreen)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Video controls
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //   children: [
                            //     _buildControlButton(
                            //       icon: Icons.replay_10,
                            //       label: '10s',
                            //       onTap: _skipBackward,
                            //     ),
                            //     _buildControlButton(
                            //       icon: _playerValue?.isPlaying ?? false
                            //           ? Icons.pause
                            //           : Icons.play_arrow,
                            //       label: _playerValue?.isPlaying ?? false
                            //           ? 'Pause'
                            //           : 'Play',
                            //       onTap: _togglePlayPause,
                            //     ),
                            //     _buildControlButton(
                            //       icon: Icons.forward_10,
                            //       label: '10s',
                            //       onTap: _skipForward,
                            //     ),
                            //     _buildControlButton(
                            //       icon: Icons.high_quality,
                            //       label: _currentQuality,
                            //       onTap: _showQualitySelector,
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ));
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
