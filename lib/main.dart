import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const BaseChurchApp());
}
