// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:nota_premiada/services/cpf_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:nota_premiada/config/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final cpfController = TextEditingController();
  final phoneController = TextEditingController();
  final birthController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  String? error;
  Map<String, String> fieldErrors = {};

  // Função para validar o CPF
  bool validateCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), ''); // Remover tudo que não é número

    if (cpf.length != 11) return false;

    // CPF com números repetidos são inválidos
    if (RegExp(r"(\d)\1{10}").hasMatch(cpf)) return false;

    List<int> cpfDigits = cpf.split('').map(int.parse).toList();
    int sum1 = 0, sum2 = 0;

    // Cálculo do primeiro dígito verificador
    for (int i = 0; i < 9; i++) {
      sum1 += cpfDigits[i] * (10 - i);
    }

    int remainder1 = sum1 % 11;
    int check1 = remainder1 < 2 ? 0 : 11 - remainder1;
    if (check1 != cpfDigits[9]) return false;

    // Cálculo do segundo dígito verificador
    for (int i = 0; i < 10; i++) {
      sum2 += cpfDigits[i] * (11 - i);
    }

    int remainder2 = sum2 % 11;
    int check2 = remainder2 < 2 ? 0 : 11 - remainder2;
    if (check2 != cpfDigits[10]) return false;

    return true;
  }

  // Função de registro
  Future<void> register() async {
    setState(() {
      loading = true;
      error = null;
      fieldErrors.clear();
    });

    // Validação de campos
    if (nameController.text.isEmpty ||
        cpfController.text.isEmpty ||
        phoneController.text.isEmpty ||
        birthController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      setState(() {
        error = 'Por favor, preencha todos os campos.';
        loading = false;
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        error = 'As senhas não coincidem.';
        loading = false;
      });
      return;
    }

    // Validação do CPF
    if (!validateCPF(cpfController.text)) {
      setState(() {
        error = 'CPF inválido.';
        loading = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': nameController.text,
          'cpf': cpfController.text.replaceAll(RegExp(r'\D'), ''),
          'phone': phoneController.text,
          'birth_date': birthController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        final errors = data['errors'] as Map<String, dynamic>;
        setState(() {
          fieldErrors = errors.map(
            (key, value) => MapEntry(key, (value as List).join('\n')),
          );
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          error = data['message'] ?? 'Erro ao cadastrar. Tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erro de conexão com o servidor.';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  // Função para abrir o DatePicker
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        birthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  InputDecoration inputDecoration(
    String label,
    IconData icon, {
    String? errorText,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: inputDecoration(
                'Nome completo',
                Icons.person,
                errorText: fieldErrors['name'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [CpfInputFormatter()],
              decoration: inputDecoration(
                'CPF',
                Icons.badge,
                errorText: fieldErrors['cpf'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [MaskedInputFormatter('(##) #####-####')],
              decoration: inputDecoration(
                'Telefone',
                Icons.phone,
                errorText: fieldErrors['phone'],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectBirthDate(context),
              child: TextField(
                controller: birthController,
                enabled: false,
                decoration: inputDecoration(
                  'Data de nascimento',
                  Icons.cake,
                  errorText: fieldErrors['birth_date'],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration(
                'E-mail',
                Icons.email,
                errorText: fieldErrors['email'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputDecoration(
                'Senha',
                Icons.lock,
                errorText: fieldErrors['password'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: inputDecoration(
                'Confirmar senha',
                Icons.lock_outline,
                errorText: fieldErrors['password_confirmation'],
              ),
            ),
            const SizedBox(height: 24),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.white),
                label:
                    loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Cadastrar',
                          style: TextStyle(color: Colors.white),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: loading ? null : register,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
