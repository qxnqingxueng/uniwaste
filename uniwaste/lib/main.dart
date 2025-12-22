import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:user_repository/user_repository.dart';
import 'package:uniwaste/app.dart';
import 'package:uniwaste/simple_bloc_observer.dart';

// ✅ THIS IMPORT IS CRITICAL
import 'package:merchant_repository/merchant_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  Bloc.observer = SimpleBlocObserver();

  final userRepository = FirebaseUserRepo();

  // ✅ Now this line will work because the barrel file exports it
  final merchantRepository = FirebaseMerchantRepo();

  runApp(MyApp(userRepository, merchantRepository));
}
