// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:nota_premiada/screens/webview_page.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:nota_premiada/config/api_config.dart';

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
      Uri.parse('${ApiConfig.baseUrl}/cupons'),
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

  void abrirNota(String chave) {
    final url =
        'https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=$chave|2|1|1|';

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewPage(url: url)),
    );
  }

  // Função para cadastrar o cupom
  Future<void> cadastrarCupom(String chaveAcesso) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getInt(
      'user_id',
    ); // Supondo que o user_id esteja salvo

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cupons'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'qr_code': chaveAcesso,
        'user_id': userId, // Envia o user_id
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));

      // Recarregar os cupons após o cadastro
      fetchCupons();
    } else {
      final errorData = json.decode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorData['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Cupons')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchCupons, // Função de atualização ao puxar para baixo
        child:
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
                    final chave = cupom['chave_acesso'] ?? '';
                    final valorTotal =
                        cupom['valor_total'] ?? '0.00'; // Adicionei valor_total

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
                            const SizedBox(height: 4),
                            Text(
                              'Valor Total: R\$ $valorTotal',
                            ), // Exibindo valor_total
                            const SizedBox(height: 8),
                            if (numeros.isNotEmpty) Text('Números p/ Sorteio'),
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
                                label: const Text('Ver nota (SEFAZ)'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navegar para o scanner de QR Code
          String? qrCode = await SimpleBarcodeScanner.scanBarcode(
            context,
            barcodeAppBar: const BarcodeAppBar(
              appBarTitle: 'Scanner QR Code',
              centerTitle: false,
              enableBackButton: true,
              backButtonIcon: Icon(Icons.arrow_back_ios),
            ),
            isShowFlashIcon: true,
            delayMillis: 2000,
            cameraFace: CameraFace.front,
          );

          if (qrCode != null && qrCode.isNotEmpty) {
            // Após o QR Code ser escaneado, cadastrar o cupom
            cadastrarCupom(qrCode);
          }
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Ler Nota'),
      ),
    );
  }
}
