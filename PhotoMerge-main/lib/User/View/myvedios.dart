import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:photomerge/main.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00A19A); // Teal main color
  static const Color secondaryColor =
      Color(0xFFF8FAFA); // Very light background
  static const Color accentColor = Color(0xFF005F5C); // Darker teal for accents
  static const Color cardColor = Colors.white; // White card backgrounds
  static const Color textColor = Color(0xFF212121); // Primary text
  static const Color subtitleColor = Color(0xFF757575); // Subtitle text
}

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

  // Theme spacing
  final double _standardPadding = 12.0;
  final double _cardBorderRadius = 12.0;

  // Categories matching AddVediourl
  final List<String> _categories = ['All', 'Training', 'Other'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 24),
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
              fontSize: 20,
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
      color: AppTheme.primaryColor,
      onRefresh: () async => setState(() {}),
      child: Column(
        children: [
          // Categories row
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: _standardPadding,
            ),
            child: _buildCategoryChips(),
          ),

          // Videos grid
          Expanded(
            child: _buildVideosGrid(),
          ),
        ],
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(fontSize: 15, color: AppTheme.textColor),
        decoration: InputDecoration(
          hintText: 'Search videos...',
          hintStyle:
              GoogleFonts.poppins(color: AppTheme.subtitleColor, fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.primaryColor, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: AppTheme.subtitleColor, size: 18),
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
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.textColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
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

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: _standardPadding),
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final videoData = videos[index].data() as Map<String, dynamic>;
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CompactVideoCard(
                          videoData: videoData,
                          videoId: videos[index].id,
                          borderRadius: _cardBorderRadius,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 42),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: GoogleFonts.poppins(
                  color: AppTheme.subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: AppTheme.subtitleColor, size: 42),
            const SizedBox(height: 16),
            Text(
              'No videos available',
              style: GoogleFonts.poppins(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some videos to get started!',
              style: GoogleFonts.poppins(
                  color: AppTheme.subtitleColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppTheme.subtitleColor, size: 42),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                color: AppTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: GoogleFonts.poppins(
                  color: AppTheme.subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Clear Search',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Redesigned compact video card
class CompactVideoCard extends StatelessWidget {
  final Map<String, dynamic> videoData;
  final String videoId;
  final double borderRadius;

  const CompactVideoCard({
    super.key,
    required this.videoData,
    required this.videoId,
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

    // Constrain the card width to a standard size (similar to YouTube mobile)
    final cardWidth = MediaQuery.of(context).size.width.clamp(0.00, 360.00);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
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
              // Thumbnail with play overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildThumbnail(youtubeId),
                    ),
                  ),
                  // Play button overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
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
                  // Category pill
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Title and metadata
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail placeholder or channel icon (optional)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$category • $timeAgo',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.subtitleColor,
                            ),
                          ),
                        ],
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
        imageUrl:
            'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg', // Higher quality thumbnail
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Center(
            child:
                Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.videocam_off_rounded, color: Colors.grey, size: 32),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
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
  List<String> _availableQualities = ['auto', '360p', '720p'];
  VideoAudioHandler? _audioHandler;

  @override
  void initState() {
    super.initState();
    NoScreenshot.instance.screenshotOff();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudioSession();
    });
  }

  Future<void> _initializeAudioSession() async {
    debugPrint('VideoPlayerScreen: Initializing audio session');
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions(
          AVAudioSessionCategoryOptions.allowBluetooth.value |
              AVAudioSessionCategoryOptions.defaultToSpeaker.value,
        ),
      ));

      final activated = await session.setActive(true);
      debugPrint('VideoPlayerScreen: Audio session activated=$activated');

      // Use singleton audioHandler from main.dart
      _audioHandler = audioHandler as VideoAudioHandler?;

      final videoId = widget.videoId.trim();
      final title = widget.title.trim();
      if (videoId.isNotEmpty && title.isNotEmpty) {
        debugPrint(
            'VideoPlayerScreen: Updating MediaItem with videoId=$videoId, title=$title');
        _audioHandler!.updateMediaItem(MediaItem(
          id: videoId,
          title: title,
          artist: 'YouTube',
          duration: null,
        ));
      } else {
        debugPrint(
            'Error: Invalid inputs - videoId: "$videoId", title: "$title"');
      }

      // Sync YouTube controller when playback state changes
      _audioHandler!.playbackState.listen((state) {
        debugPrint(
            'VideoPlayerScreen: Playback state changed - playing=${state.playing}');
        if (state.playing && !_controller.value.isPlaying) {
          debugPrint('VideoPlayerScreen: Playing video');
          _controller.play(); // Only control video player
        } else if (!state.playing && _controller.value.isPlaying) {
          debugPrint('VideoPlayerScreen: Pausing video');
          _controller.pause(); // Only control video player
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error initializing AudioService: $e\n$stackTrace');
    }
  }

  void _onPlayerValueChange() {
    if (!mounted) return;
    _playerValue = _controller.value;
    if (_audioHandler != null) {
      final newState = PlaybackState(
        playing: _controller.value.isPlaying,
        controls: [
          _controller.value.isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
        ],
        processingState: _controller.value.playerState == PlayerState.buffering
            ? AudioProcessingState.buffering
            : AudioProcessingState.ready,
      );
      if (newState != _audioHandler!.playbackState.value) {
        debugPrint(
            'VideoPlayerScreen: Updating playback state - playing=${newState.playing}');
        _audioHandler!.playbackState.add(newState);
      }
    }
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
      debugPrint('VideoPlayerScreen: Manual pause');
      _controller.pause();
      _audioHandler?.pause();
    } else {
      debugPrint('VideoPlayerScreen: Manual play');
      _controller.play();
      _audioHandler?.play();
    }
    setState(() {});
  }

  void _syncPlaybackWithAudioHandler() {
    _audioHandler?.playbackState.listen((state) {
      if (state.playing && !_controller.value.isPlaying) {
        _controller.play();
      } else if (!state.playing && _controller.value.isPlaying) {
        _controller.pause();
      }
    });
  }

  // Future<void> _changeQuality(String quality) async {
  //   final currentPosition = _controller.value.position;
  //   final wasPlaying = _controller.value.isPlaying;

  //   // Explicitly pause before disposing
  //   _controller.pause();
  //   await _audioHandler?.pause();

  //   // Short delay to allow pause to take effect
  //   await Future.delayed(const Duration(milliseconds: 300));

  //   _controller.removeListener(_onPlayerValueChange);
  //   _controller.dispose();

  //   // Create new controller
  //   _controller = YoutubePlayerController(
  //     initialVideoId: widget.videoId,
  //     flags: YoutubePlayerFlags(
  //       autoPlay: wasPlaying, // Resume only if was playing
  //       mute: false,
  //       enableCaption: true,
  //       forceHD: quality == '720p',
  //     ),
  //   );

  //   _controller.addListener(_onPlayerValueChange);
  //   _controller.seekTo(currentPosition);

  //   _syncPlaybackWithAudioHandler();

  //   setState(() {
  //     _currentQuality = quality;
  //   });

  //   Navigator.pop(context);
  // }

  // void _showQualitySelector() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.all(16.0),
  //               child: Text(
  //                 'Select Quality',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //             const Divider(height: 1),
  //             ListView.builder(
  //               shrinkWrap: true,
  //               itemCount: _availableQualities.length,
  //               itemBuilder: (context, index) {
  //                 final quality = _availableQualities[index];
  //                 return ListTile(
  //                   title: Text(quality),
  //                   trailing: _currentQuality == quality
  //                       ? const Icon(Icons.check, color: Color(0xFF4CAF50))
  //                       : null,
  //                   onTap: () => _changeQuality(quality),
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    NoScreenshot.instance.screenshotOn();
    _controller.removeListener(_onPlayerValueChange);
    _controller.dispose();
    _audioHandler?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _controller.toggleFullScreenMode();
          return false;
        } else {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          return true;
        }
      },
      child: YoutubePlayerBuilder(
        onExitFullScreen: () {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          setState(() {
            _isFullScreen = false;
          });
        },
        onEnterFullScreen: () {
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
          bottomActions: [
            CurrentPosition(),
            ProgressBar(
              isExpanded: true,
              colors: const ProgressBarColors(
                playedColor: Color(0xFF4CAF50),
                handleColor: Color(0xFF4CAF50),
              ),
            ),
            RemainingDuration(),
            IconButton(
              onPressed: _skipBackward,
              icon: const Icon(Icons.replay_10, color: Colors.white),
            ),
            IconButton(
              onPressed: _skipForward,
              icon: const Icon(Icons.forward_10, color: Colors.white),
            ),
            // IconButton(
            //   icon: const Icon(Icons.settings, color: Colors.white),
            //   onPressed: _showQualitySelector,
            // ),
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
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF00A19A)),
                      onPressed: () {
                        SystemChrome.setPreferredOrientations(
                            [DeviceOrientation.portraitUp]);
                        Navigator.pop(context);
                      },
                    ),
                    title: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00A19A),
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
                player,
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
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
