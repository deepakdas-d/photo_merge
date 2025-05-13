// // import 'package:flutter/material.dart';
// // import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// // import 'package:flutter/services.dart';

// // class VideoPlayerPage extends StatefulWidget {
// //   final String videoId;
// //   final String videoTitle;

// //   const VideoPlayerPage({
// //     super.key,
// //     required this.videoId,
// //     required this.videoTitle,
// //   });

// //   @override
// //   State<VideoPlayerPage> createState() => _VideoPlayerPageState();
// // }

// // class _VideoPlayerPageState extends State<VideoPlayerPage> {
// //   late YoutubePlayerController _controller;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = YoutubePlayerController(
// //       initialVideoId: widget.videoId,
// //       flags: const YoutubePlayerFlags(
// //         autoPlay: true,
// //         mute: false,
// //         enableCaption: true,
// //       ),
// //     );

// //     // Allow all orientations for video playback
// //     SystemChrome.setPreferredOrientations([
// //       DeviceOrientation.portraitUp,
// //       DeviceOrientation.landscapeLeft,
// //       DeviceOrientation.landscapeRight,
// //     ]);
// //   }

// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     // Reset to portrait orientation when exiting
// //     SystemChrome.setPreferredOrientations([
// //       DeviceOrientation.portraitUp,
// //     ]);
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       appBar: AppBar(
// //         backgroundColor: Colors.black,
// //         title: Text(
// //           widget.videoTitle,
// //           style: const TextStyle(color: Colors.white),
// //           maxLines: 1,
// //           overflow: TextOverflow.ellipsis,
// //         ),
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.white),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //       ),
// //       body: Center(
// //         child: YoutubePlayer(
// //           controller: _controller,
// //           showVideoProgressIndicator: true,
// //           progressIndicatorColor: Colors.red,
// //           progressColors: const ProgressBarColors(
// //             playedColor: Colors.red,
// //             handleColor: Colors.redAccent,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:flutter/services.dart';

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoId;
//   final String title;

//   const VideoPlayerScreen({
//     super.key,
//     required this.videoId,
//     required this.title,
//   });

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   bool _isFullScreen = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = YoutubePlayerController(
//       initialVideoId: widget.videoId,
//       flags: YoutubePlayerFlags(
//         autoPlay: true,
//         mute: false,
//         enableCaption: true,
//         forceHD: false,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return YoutubePlayerBuilder(
//       onExitFullScreen: () {
//         // The player forces portraitUp after exiting fullscreen, so we need to
//         // restore the preferred orientations
//         setState(() {
//           _isFullScreen = false;
//         });
//       },
//       onEnterFullScreen: () {
//         setState(() {
//           _isFullScreen = true;
//         });
//       },
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: true,
//         progressIndicatorColor: Color(0xFF4CAF50),
//         progressColors: ProgressBarColors(
//           playedColor: Color(0xFF4CAF50),
//           handleColor: Color(0xFF4CAF50),
//         ),
//         onReady: () {
//           // Player is ready
//         },
//       ),
//       builder: (context, player) {
//         return Scaffold(
//           appBar: _isFullScreen
//               ? null
//               : AppBar(
//                   backgroundColor: Colors.white,
//                   leading: IconButton(
//                     icon: Icon(Icons.arrow_back),
//                     color: Colors.green,
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   title: Text(
//                     widget.title,
//                     style: GoogleFonts.oswald(
//                       color: Colors.green,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   elevation: 0,
//                 ),
//           body: Column(
//             children: [
//               // YouTube Player
//               player,

//               // Video information
//               if (!_isFullScreen)
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.title,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         // Video controls
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             _buildControlButton(
//                               icon: Icons.replay_10,
//                               label: '10s',
//                               onTap: () {
//                                 final currentPosition =
//                                     _controller.value.position.inSeconds;
//                                 _controller.seekTo(
//                                     Duration(seconds: currentPosition - 10));
//                               },
//                             ),
//                             _buildControlButton(
//                               icon: _controller.value.isPlaying
//                                   ? Icons.pause
//                                   : Icons.play_arrow,
//                               label: _controller.value.isPlaying
//                                   ? 'Pause'
//                                   : 'Play',
//                               onTap: () {
//                                 if (_controller.value.isPlaying) {
//                                   _controller.pause();
//                                 } else {
//                                   _controller.play();
//                                 }
//                                 setState(() {});
//                               },
//                             ),
//                             _buildControlButton(
//                               icon: Icons.forward_10,
//                               label: '10s',
//                               onTap: () {
//                                 final currentPosition =
//                                     _controller.value.position.inSeconds;
//                                 _controller.seekTo(
//                                     Duration(seconds: currentPosition + 10));
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(50),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Color(0xFF4CAF50).withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 color: Color(0xFF4CAF50),
//                 size: 28,
//               ),
//             ),
//             SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
