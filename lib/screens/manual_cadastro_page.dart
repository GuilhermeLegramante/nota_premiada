import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';

class ManualCadastroPage extends StatefulWidget {
  const ManualCadastroPage({super.key});

  @override
  State<ManualCadastroPage> createState() => _ManualCadastroPageState();
}

class _ManualCadastroPageState extends State<ManualCadastroPage> {
  final _chaveController = TextEditingController();
  final _valorController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _obsController = TextEditingController();

  bool loading = false;
  String? error;
  Map<String, String> fieldErrors = {};

  File? _imagemNota;
  final ImagePicker _picker = ImagePicker();

  Future<void> _tirarFoto() async {
    final XFile? arquivo = await _picker.pickImage(source: ImageSource.camera);
    if (arquivo != null) {
      setState(() {
        _imagemNota = File(arquivo.path);
      });
    }
  }

  Future<void> cadastrarManual() async {
    setState(() {
      loading = true;
      error = null;
      fieldErrors.clear();
    });

    if (_chaveController.text.length < 44) {
      setState(() {
        fieldErrors['chave_acesso'] = 'Informe ao menos 44 dígitos da chave.';
        loading = false;
      });
      return;
    }

    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (valor == null) {
      setState(() {
        fieldErrors['valor_total'] = 'Informe um valor válido.';
        loading = false;
      });
      return;
    }

    if (_fornecedorController.text.isEmpty) {
      setState(() {
        fieldErrors['fornecedor'] = 'Informe o fornecedor.';
        loading = false;
      });
      return;
    }

    if (_imagemNota == null) {
      setState(() {
        fieldErrors['arquivo'] = 'Por favor, tire uma foto da nota.';
        loading = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final uri = Uri.parse('${ApiConfig.baseUrl}/cupons/manual');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $token'
            ..fields['chave_acesso'] = _chaveController.text.trim()
            ..fields['valor_total'] = valor.toString()
            ..fields['fornecedor'] = _fornecedorController.text.trim()
            ..fields['observacao'] = _obsController.text.trim();

      if (_imagemNota != null) {
        request.files.add(
          await http.MultipartFile.fromPath('arquivo', _imagemNota!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Cadastro realizado.')),
        );
        Navigator.pop(context);
      } else {
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

  InputDecoration inputDecoration(
    String label,
    IconData icon, {
    String? errorText,
    int? maxLength,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      errorText: errorText,
      counterText: '', // remove contador de caracteres
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _widgetFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto da Nota (obrigatório)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_imagemNota != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_imagemNota!, height: 150, fit: BoxFit.cover),
          ),
        TextButton.icon(
          onPressed: _tirarFoto,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Tirar foto da nota'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro Manual',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'É responsabilidade do usuário informar corretamente os dados da nota fiscal.',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _chaveController,
              maxLength: 60,
              keyboardType: TextInputType.number,
              decoration: inputDecoration(
                'Chave de Acesso (44 dígitos)',
                Icons.qr_code,
                errorText: fieldErrors['chave_acesso'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: inputDecoration(
                'Valor Total',
                Icons.attach_money,
                errorText: fieldErrors['valor_total'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fornecedorController,
              decoration: inputDecoration(
                'Fornecedor',
                Icons.store,
                errorText: fieldErrors['fornecedor'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _obsController,
              decoration: inputDecoration(
                'Observações (opcional)',
                Icons.notes,
              ),
            ),
            const SizedBox(height: 16),
            _widgetFoto(),
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
                icon: const Icon(Icons.save, color: Colors.white),
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
                onPressed: loading ? null : cadastrarManual,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
