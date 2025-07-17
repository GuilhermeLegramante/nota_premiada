import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nota_premiada/config/api_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AtualizacaoUtil {
  static Future<void> verificarAtualizacao(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final versaoAtual = info.version;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/versao-app'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final versaoMinima = data['minima'];
        final versaoUltima = data['ultima'];
        final urlDownload = data['url_android'];

        if (_compararVersao(versaoAtual, versaoMinima) < 0) {
          // Atualização obrigatória
          _mostrarDialogAtualizacao(context, urlDownload, obrigatoria: true);
        } else if (_compararVersao(versaoAtual, versaoUltima) < 0) {
          // Atualização recomendada
          _mostrarDialogAtualizacao(context, urlDownload, obrigatoria: false);
        }
      }
    } catch (e) {
      // Silencia falha de rede (útil para modo offline)
    }
  }

  static int _compararVersao(String v1, String v2) {
    final a = v1.split('.').map(int.parse).toList();
    final b = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return a[i] - b[i];
    }
    return 0;
  }

  static void _mostrarDialogAtualizacao(
    BuildContext context,
    String url, {
    bool obrigatoria = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !obrigatoria,
      builder:
          (_) => AlertDialog(
            title: const Text('Atualização disponível'),
            content: Text(
              obrigatoria
                  ? 'Uma nova versão do app é obrigatória para continuar.'
                  : 'Há uma nova versão disponível. Deseja atualizar agora?',
            ),
            actions: [
              if (!obrigatoria)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Mais tarde'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text('Atualizar'),
              ),
            ],
          ),
    );
  }
}
