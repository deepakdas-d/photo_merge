import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:photomerge/Admin/image_/add_posters.dart';
import 'package:photomerge/Admin/videos/add_vediourl.dart';
import 'package:photomerge/Admin/image_/addcarousel.dart';
import 'package:photomerge/Admin/adminhome.dart';
import 'package:photomerge/Admin/create_admin.dart';
import 'package:photomerge/Admin/user/listusers.dart';
import 'package:photomerge/Admin/user/subscriptionmanage.dart';
import 'package:photomerge/Admin/videos/listvideos.dart';
import 'package:photomerge/Authentication/authservice.dart';
import 'package:photomerge/Authentication/signin.dart';
import 'package:photomerge/Authentication/signup.dart';
// import 'package:photomerge/User/View/Wrapper/userdashboardwrapper.dart';
import 'package:photomerge/User/View/about.dart';
import 'package:photomerge/User/View/categorylist.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:photomerge/User/View/listimages.dart';
import 'package:photomerge/User/View/myvedios.dart';
import 'package:photomerge/User/View/profile.dart';
import 'package:photomerge/User/View/provider/authprovider.dart';
import 'package:photomerge/User/View/provider/carousalprovider.dart';
import 'package:photomerge/User/View/provider/categoryprovider.dart';
import 'package:photomerge/User/View/provider/recentimage_provider.dart';
import 'package:photomerge/User/View/provider/userprovider.dart';
import 'package:photomerge/User/View/support.dart';
import 'package:photomerge/User/View/usersubscription.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

late final AudioHandler audioHandler;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await AwesomeNotifications().initialize(
    null, // Default icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );
  try {
    debugPrint('main: Initializing AudioService...');
    audioHandler = await AudioService.init(
      builder: () => VideoAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.photomerge.video_channel',
        androidNotificationChannelName: 'Video Playback',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
      ),
    );
    debugPrint('main: AudioService initialized');
  } catch (e) {
    debugPrint('main: AudioService init error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviders()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => RecentImagesProvider()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()),

        // Add more providers here as needed
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Role Based Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/signup': (context) => SignupPage(),
        '/login': (context) => LoginPage(),
        '/user': (context) => UserDashboard(),
        '/admin': (context) => AdminDashboard(),
        '/profile': (context) => ProfilePage(),
        '/createadmin': (context) => create_admin(),
        '/craeteimage': (context) => AddImagePage(),
        '/listimages': (context) => ListImages(),
        '/Category': (context) => CategoryListPage(),
        '/listusers': (context) => UserListPage(),
        '/submanage': (context) => AdminSubscriptionPage(),
        '/usersubscription': (context) => UserSubscriptionPage(),
        '/carousel': (context) => AdminImageUploadPage(),
        '/about': (context) => AboutPage(),
        '/support': (context) => SupportPage(),
        '/vediourl': (context) => AddVediourl(),
        '/listvedios': (context) => AllVideosPage(),
        '/adminlistvedio': (context) => VideoListPage(),
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay(
      {required this.isLoading, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.white
                .withOpacity(0.4), // Light, semi-transparent background
            child: Center(
              child: Lottie.asset(
                'assets/animations/empty_gallery.json', // Example Lottie animation URL
                width: 100, // Adjust size as needed
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }
}

class VideoAudioHandler extends BaseAudioHandler {
  VideoAudioHandler() {
    debugPrint('VideoAudioHandler: Initialized');
  }

  @override
  Future<void> play() async {
    debugPrint('VideoAudioHandler: play() called');
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [MediaControl.pause, MediaControl.stop],
    ));
  }

  @override
  Future<void> pause() async {
    debugPrint('VideoAudioHandler: pause() called');
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [MediaControl.play, MediaControl.stop],
    ));
  }

  @override
  Future<void> stop() async {
    debugPrint('VideoAudioHandler: stop() called');
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> onTaskRemoved() async {
    debugPrint('VideoAudioHandler: onTaskRemoved');
    await stop();
  }

  @override
  Future<void> onNotificationClicked(bool show) async {
    debugPrint('VideoAudioHandler: Notification clicked, show=$show');
  }

  @override
  Future<void> onMediaButtonEvent(MediaButton button) async {
    debugPrint('VideoAudioHandler: MediaButton event: $button');

    // Only one case exists currently: MediaButton.media
    if (playbackState.value.playing) {
      await pause();
    } else {
      await play();
    }
  }
}
