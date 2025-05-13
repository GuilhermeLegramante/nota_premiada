import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    final response = await http.post(
      Uri.parse('http://192.168.0.73/notapremiada/public/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('resposta da requisição');
      print(data);
      final token = data['access_token'];

      if (token != null && token is String) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          error = 'Token ausente ou inválido';
        });
      }
    } else {
      final data = json.decode(response.body);
      setState(() {
        error = data['message'] ?? 'Login inválido';
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: const Text('Entrar')),
          ],
        ),
      ),
    );
  }
}
