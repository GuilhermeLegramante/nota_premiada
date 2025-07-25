// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nota_premiada/config/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool loading = false;
  String? error;
  String? emailError;
  String? passwordError;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      emailError = null;
      passwordError = null;
      error = null;
    });

    bool hasError = false;

    if (email.isEmpty) {
      emailError = 'Informe seu e-mail';
      hasError = true;
      emailFocusNode.requestFocus();
    } else if (password.isEmpty) {
      passwordError = 'Informe sua senha';
      hasError = true;
      passwordFocusNode.requestFocus();
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        final userId = data['user']['id'];

        if (token != null && token is String && userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setInt('user_id', userId);

          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          setState(() {
            error = 'Token ou ID de usuário ausente ou inválido';
          });
        }
      } else {
        final data = json.decode(response.body);
        setState(() {
          error = data['message'] ?? 'Login inválido';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erro de conexão. Tente novamente.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const Icon(Icons.receipt_long, size: 80, color: Colors.indigo),
              Image.asset('assets/logo_nota_premiada.png', height: 100),
              const SizedBox(height: 16),
              // const Text(
              //   'Nota Premiada',
              //   style: TextStyle(
              //     fontSize: 28,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.indigo,
              //   ),
              // ),
              const SizedBox(height: 32),

              TextField(
                controller: emailController,
                focusNode: emailFocusNode,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  errorText: emailError,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocusNode);
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  errorText: passwordError,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => login(),
              ),
              const SizedBox(height: 20),

              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : login,
                  icon: const Icon(Icons.login, color: Colors.white),
                  label:
                      loading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                          : const Text(
                            'Entrar',
                            style: TextStyle(color: Colors.white),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Cadastre-se'),
                  ),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text('Esqueci minha senha'),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Text(
                '© 2025 Nota Premiada',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
