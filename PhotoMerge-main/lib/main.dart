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
        '/user': (context) => UserDashboardContent(),
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
