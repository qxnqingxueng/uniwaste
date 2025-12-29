import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/home/home_screen.dart';
import 'package:uniwaste/screens/auth/auth_wrapper.dart';
import 'package:uniwaste/services/notification_service.dart'; // [ADDED]
import 'package:uniwaste/screens/waste-to-resources/company/waste_collection_screen.dart'; // [ADDED]

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  State<MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  // GlobalKey to allow navigation from outside the widget tree (notification service)
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initNotificationService();
  }

  // Initialize and listen for notification clicks
  void _initNotificationService() async {
    final service = NotificationService();
    await service.init(); // Ensure service is initialized
    service.onNotificationClick.listen((payload) {
      if (payload == 'waste_collection') {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const WasteCollectionScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // Attach key
      title: 'University Waste Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(210, 220, 182, 0.3),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          if (state.status == AuthenticationStatus.authenticated) {
            return const HomeScreen();
          } else {
            return const AuthWrapper();
          }
        },
      ),
    );
  }
}
