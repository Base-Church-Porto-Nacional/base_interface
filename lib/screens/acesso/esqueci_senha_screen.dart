import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/acesso_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

const _mensagemEnviado =
    'Se houver uma conta com esse contato, enviamos um link pelo WhatsApp. '
    'Se não receber, peça um novo link à secretaria da igreja.';

/// Tela pública `/esqueci-senha`. Sempre mostra a mesma mensagem após enviar.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _identificador = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _identificador.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final valor = _identificador.text.trim();
    if (valor.isEmpty) {
      setState(() => _erro = 'Informe seu e-mail ou telefone.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await context.read<AcessoService>().esqueciSenha(valor);
      if (mounted) setState(() => _enviado = true);
    } on ApiException catch (e) {
      // 429 e falhas de rede: mostra o aviso do servidor, sem revelar nada.
      if (mounted) setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Esqueci minha senha',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_enviado)
                        Text(_mensagemEnviado, style: theme.textTheme.bodyLarge)
                      else ...[
                        TextField(
                          controller: _identificador,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail ou telefone',
                          ),
                          onSubmitted: (_) => _enviando ? null : _enviar(),
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _erro!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _enviando ? null : _enviar,
                          child: _enviando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Enviar link'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Voltar ao login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
