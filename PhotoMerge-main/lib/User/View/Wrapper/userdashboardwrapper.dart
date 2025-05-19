// import 'package:flutter/material.dart';
// import 'package:photomerge/User/View/home.dart';
// import 'package:photomerge/User/View/provider/authprovider.dart';
// import 'package:photomerge/User/View/provider/carousalprovider.dart';
// import 'package:photomerge/User/View/provider/categoryprovider.dart';
// import 'package:photomerge/User/View/provider/recentimage_provider.dart';
// import 'package:photomerge/User/View/provider/userprovider.dart';
// import 'package:provider/provider.dart';

// class UserDashboardWrapper extends StatelessWidget {
//   const UserDashboardWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProviders()),
//         ChangeNotifierProvider(create: (_) => UserDataProvider()),
//         ChangeNotifierProvider(create: (_) => CarouselProvider()),
//         ChangeNotifierProvider(create: (_) => CategoriesProvider()),
//         ChangeNotifierProvider(create: (_) => RecentImagesProvider()),
//       ],
//       child: UserDashboardContent(), // Only the real content widget goes here
//     );
//   }
// }
