// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nota_premiada/screens/webview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:nota_premiada/config/api_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> cupons = [];
  bool loading = true;

  int totalCupons = 0;
  int totalNumerosSorteio = 0;
  double saldoParaSorteio = 0.0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final responseCupons = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cupons'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseSaldo = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/saldo'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (responseCupons.statusCode == 200) {
        final data = json.decode(responseCupons.body);
        setState(() {
          cupons = data;
          totalCupons = data.length;
          totalNumerosSorteio = data.fold(0, (sum, cupom) {
            final numeros = cupom['numeros_sorteio'] ?? [];
            return sum + numeros.length;
          });
        });
      }

      if (responseSaldo.statusCode == 200) {
        final dataSaldo = json.decode(responseSaldo.body);
        setState(() {
          final rawSaldo =
              double.tryParse(dataSaldo['saldo'].toString()) ?? 0.0;
          saldoParaSorteio = rawSaldo;
        });
      }
    } catch (e) {
      // Erro silencioso ou log
    }

    setState(() {
      loading = false;
    });
  }

  String formatarData(String dataIso) {
    try {
      final date = DateTime.parse(dataIso);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dataIso;
    }
  }

  Future<void> _launchSefazUrl(String chave) async {
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

      fetchDashboardData();
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
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'Nota Premiada Cacequi',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('access_token');
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Icon(Icons.receipt_long, color: Colors.blue),
                          title: Text('Cupons Cadastrados'),
                          trailing: Text(
                            '$totalCupons',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.green,
                          ),
                          title: Text('Saldo para Sorteio'),
                          trailing: Text(
                            NumberFormat.currency(
                              locale: 'pt_BR',
                              symbol: 'R\$',
                            ).format(saldoParaSorteio),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Icon(
                            Icons.confirmation_num,
                            color: Colors.purple,
                          ),
                          title: Text('Números para Sorteio'),
                          trailing: Text(
                            '$totalNumerosSorteio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Cupons Cadastrados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children:
                            cupons.map((cupom) {
                              final fornecedor =
                                  cupom['fornecedor'] ?? 'Sem fornecedor';
                              final dataCadastro = formatarData(
                                cupom['data_cadastro'] ?? '',
                              );
                              final numeros = cupom['numeros_sorteio'] ?? [];
                              final chave = cupom['chave_acesso'] ?? '';
                              final valorTotal = cupom['valor_total'] ?? '0.00';

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'Valor Total: ${NumberFormat.simpleCurrency(locale: 'pt_BR').format(double.tryParse(valorTotal) ?? 0)}',
                                        ),
                                        const SizedBox(height: 8),
                                        if (numeros.isNotEmpty)
                                          const Text('Números p/ Sorteio'),
                                        Wrap(
                                          spacing: 6,
                                          children:
                                              numeros
                                                  .map<Widget>(
                                                    (n) => Chip(
                                                      label: Text(
                                                        n['id'].toString(),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                        const SizedBox(height: 8),
                                        if (chave.isNotEmpty)
                                          TextButton.icon(
                                            onPressed:
                                                () => _launchSefazUrl(chave),
                                            icon: const Icon(
                                              Icons.receipt_long,
                                            ),
                                            label: const Text(
                                              'Ver nota (SEFAZ)',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
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
            cameraFace: CameraFace.back,
          );

          if (qrCode != null && qrCode.isNotEmpty) {
            // Após o QR Code ser escaneado, cadastrar o cupom
            cadastrarCupom(qrCode);
          }
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Ler Nota'),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(12),
        child: Text(
          '© ${DateTime.now().year} Nota Premiada - Prefeitura de Cacequi/RS',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }
}
