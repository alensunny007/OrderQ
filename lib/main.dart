import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:orderq/Students/signupwithcredentials.dart';
import 'package:orderq/pages/loginpage.dart';

import 'package:orderq/pages/Signupby.dart';

import 'pages/loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OrderQ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      routes: {
        '/landingPage': (context) => const Signupas(),
        '/loginPage': (context) => const LoginPage(),
        '/signupPage': (context) => const SignupWithCredentials(),
      },
    );
  }
}
