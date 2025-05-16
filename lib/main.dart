import 'package:flutter/material.dart';
import 'package:nota_premiada/screens/forgot_password_page.dart';
import 'package:nota_premiada/screens/home_page.dart';
import 'package:nota_premiada/screens/login_page.dart';
import 'package:nota_premiada/screens/dashboard_page.dart';
import 'package:nota_premiada/screens/register_page.dart'; // Importando DashboardPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nota Premiada',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true, // deixa com visual moderno (Material 3)
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          iconTheme: IconThemeData(color: Colors.white), // seta
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/register': (_) => const RegisterPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/dashboard':
            (context) =>
                const DashboardPage(), // Definindo a rota para o Dashboard
      },
    );
  }
}
