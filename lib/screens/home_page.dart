import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List cupons = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCupons();
  }

  Future<void> fetchCupons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://192.168.0.73/notapremiada/public/api/cupons'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cupons = data;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      // Tratar erro
    }
  }

  String formatarData(String dataIso) {
    try {
      final date = DateTime.parse(dataIso);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dataIso;
    }
  }

  void abrirNota(String chave) async {
    final url = 'https://www.sefaz.rs.gov.br/NF-e/$chave|2|1|1|';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a nota.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Cupons')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: cupons.length,
                itemBuilder: (context, index) {
                  final cupom = cupons[index];
                  final fornecedor = cupom['fornecedor'] ?? 'Sem fornecedor';
                  final dataCadastro = formatarData(
                    cupom['data_cadastro'] ?? '',
                  );
                  final numeros = cupom['numeros_sorteio'] ?? [];
                  final chave = cupom['chave'] ?? '';

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fornecedor,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Data: $dataCadastro'),
                          const SizedBox(height: 8),
                          if (numeros.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              children:
                                  numeros
                                      .map<Widget>(
                                        (n) => Chip(label: Text(n['numero'])),
                                      )
                                      .toList(),
                            ),
                          const SizedBox(height: 8),
                          if (chave.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => abrirNota(chave),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Ver nota na Sefaz'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
