import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/auth/sign_in_screen.dart'; // try to delete this 
import 'package:uniwaste/screens/home/home_screen.dart';
import 'package:uniwaste/screens/auth/auth_wrapper.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Waste Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromRGBO(210, 220, 182, 0.3)),
        useMaterial3: true,
      ),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          if (state.status == AuthenticationStatus.authenticated) {
            // CLEANER: Just return the widget
            return const HomeScreen();
          } else {
            return const AuthWrapper();
          }
        },
      ),
    );
  }
}
