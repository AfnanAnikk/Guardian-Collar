import 'package:flutter/material.dart';
import 'pages/auth/login_main_page.dart';

void main() {
  runApp(const GuardianCollarApp());
}

class GuardianCollarApp extends StatelessWidget {
  const GuardianCollarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Collar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorSchemeSeed: const Color(0xFFD7FF5F),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginMainPage(),
    );
  }
}