import 'package:flutter/material.dart';

class SuperHome extends StatefulWidget {
   final dynamic userId;
  const SuperHome({Key? key, required this.userId}) : super(key: key);
  @override
  State<SuperHome> createState() => _SuperHomeState();
}

class _SuperHomeState extends State<SuperHome> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Super Admin Home'),
      ),
    );
  }
}