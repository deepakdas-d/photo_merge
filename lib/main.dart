import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:photomerge/Admin/add_posters.dart';
import 'package:photomerge/Admin/add_vediourl.dart';
import 'package:photomerge/Admin/addcarousel.dart';
import 'package:photomerge/Admin/adminhome.dart';
import 'package:photomerge/Admin/create_admin.dart';
import 'package:photomerge/Admin/listusers.dart';
import 'package:photomerge/Admin/subscriptionmanage.dart';
import 'package:photomerge/Authentication/authservice.dart';
import 'package:photomerge/Authentication/signin.dart';
import 'package:photomerge/Authentication/signup.dart';
import 'package:photomerge/User/View/about.dart';
import 'package:photomerge/User/View/categorylist.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:photomerge/User/View/listimages.dart';
import 'package:photomerge/User/View/myvedios.dart';
import 'package:photomerge/User/View/profile.dart';
import 'package:photomerge/User/View/support.dart';
import 'package:photomerge/User/View/usersubscription.dart';

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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
