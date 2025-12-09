import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/simple_bloc_observer.dart';
import 'package:uniwaste/app.dart'; // Import your main App widget
import 'package:user_repository/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Bloc.observer = SimpleBlocObserver();

  // Run the REAL app (not the red screen test)
  runApp(MyApp(FirebaseUserRepo()));
}
