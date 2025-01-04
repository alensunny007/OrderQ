import 'package:flutter/material.dart';
import 'pages/Loading.dart';

void main() {
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
      home: const LoadingScreen(), // Start with the loading screen
    );
  }
}
