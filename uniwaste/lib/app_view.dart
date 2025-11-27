import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/auth/sign_in_screen.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Waste Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          if (state.status == AuthenticationStatus.authenticated) {
            // If authenticated, show the Home Screen
            return Scaffold(
              appBar: AppBar(
                title: const Text('UniWaste Home'),
                actions: [
                  IconButton(
                    onPressed: () {
                      context.read<AuthenticationBloc>().add(AuthenticationLogoutRequested());
                    },
                    icon: const Icon(Icons.logout),
                  )
                ],
              ),
              body: const Center(
                child: Text('Welcome to UniWaste!'),
              ),
            );
          } else {
            // If unauthenticated (or unknown), show the Login Screen
            return const SignInScreen();
          }
        },
      ),
    );
  }
}