import 'package:base_church/providers/auth_provider.dart';
import 'package:base_church/screens/login/login_screen.dart';
import 'package:base_church/services/api_client.dart';
import 'package:base_church/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('identificadorUsaTecladoDeTextoParaEmailOuTelefone', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(ApiClient(prefs), prefs);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(authService),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final campo = tester.widget<TextField>(
      find.widgetWithText(TextField, 'E-mail ou telefone'),
    );
    expect(campo.keyboardType, TextInputType.text);
  });
}
