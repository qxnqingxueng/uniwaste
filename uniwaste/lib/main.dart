import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart'; // Your custom package
import 'package:uniwaste/app.dart'; // Your main App widget
import 'package:uniwaste/simple_bloc_observer.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. Set up the Bloc Observer (to see logs in console)
  Bloc.observer = SimpleBlocObserver();

  // 4. Run the App
  // We pass the FirebaseUserRepo to MyApp, which then injects it into the Blocs
  runApp(MyApp(FirebaseUserRepo()));
}
