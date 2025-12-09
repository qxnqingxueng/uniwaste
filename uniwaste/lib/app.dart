import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'app_view.dart';

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  const MyApp(this.userRepository, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider.value(value: userRepository),
        BlocProvider(
          create: (_) => AuthenticationBloc(userRepository: userRepository),
        ),

        // THIS IS THE CRITICAL LINE FOR YOUR CART
        BlocProvider(create: (_) => CartBloc()),
      ],
      child: const MyAppView(),
    );
  }
}
