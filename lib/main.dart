import 'package:flutter/material.dart';
import 'package:nota_premiada/screens/home_page.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota Premiada',
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
