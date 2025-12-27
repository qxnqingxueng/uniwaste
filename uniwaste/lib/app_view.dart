import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/home/home_screen.dart';
import 'package:uniwaste/screens/auth/auth_wrapper.dart';
import 'package:uniwaste/blocs/notification_bloc/notification_bloc.dart';
import 'package:user_repository/user_repository.dart';


class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state.status == AuthenticationStatus.authenticated) {
            // User logged in -> Start listening for messages
            context.read<NotificationBloc>().add(
              StartNotificationListener(state.user!.userId),
            );
          } else {
            // User logged out -> Stop listening
            context.read<NotificationBloc>().add(StopNotificationListener());
          }
        },
        child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
          builder: (context, state) {
            if (state.status == AuthenticationStatus.authenticated) {
              return const HomeScreen();
            } else {
              return const AuthWrapper();
            }
          },
        ),
      ),
    );
  }
}