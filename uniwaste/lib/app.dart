import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';
import 'package:merchant_repository/merchant_repository.dart'; // ✅ Import this
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_bloc.dart';
import 'package:uniwaste/blocs/cart_bloc/cart_event.dart';
import 'package:uniwaste/blocs/merchant_bloc/merchant_bloc.dart'; // ✅ Import this
import 'app_view.dart';
import 'package:uniwaste/blocs/merchant_order_bloc/merchant_order_bloc.dart';

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final MerchantRepository merchantRepository; // ✅ Ensure this is here

  const MyApp(this.userRepository, this.merchantRepository, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: merchantRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // 1. Auth Bloc
          BlocProvider<AuthenticationBloc>(
            create:
                (context) => AuthenticationBloc(userRepository: userRepository),
          ),

          // 2. Cart Bloc
          BlocProvider<CartBloc>(
            create: (context) => CartBloc()..add(LoadCart()),
          ),

          // 3. ✅ MERCHANT BLOC (This is likely missing!)
          BlocProvider<MerchantBloc>(
            create:
                (context) =>
                    MerchantBloc(merchantRepository: merchantRepository)
                      ..add(LoadMerchants()),
          ),

          BlocProvider<MerchantOrderBloc>(
          create: (context) => MerchantOrderBloc(),
        ),
        
        ],
        child: const MyAppView(),
      ),
    );
  }
}
