// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';
import 'package:mood_demo/firebase_options.dart';
import 'package:mood_demo/modules/home_screen.dart';
import 'package:mood_demo/modules/login/login_screen.dart';
import 'package:mood_demo/utils/bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mood Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      initialBinding: AppBinding(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        if (controller.isAuthenticated) {
          return MoodTrackerHome();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
