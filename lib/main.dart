import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'config/app_config.dart';

void main() {
  // URLs sem "#" na web: o backend envia links ${url-base}/acesso/{token}, e o nginx
  // devolve o index.html para qualquer caminho. No-op em iOS/Android.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // Lida antes do primeiro frame: a tela de carregamento troca a URL para "/".
  final rotaInicial =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final erro = AppConfig.erroDeConfiguracao;
  if (erro != null) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(erro, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(BaseChurchApp(rotaInicial: rotaInicial));
}
