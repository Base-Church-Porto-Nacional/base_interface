import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/acesso_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

const _mensagemLinkExpirado =
    'Este link expirou ou já foi usado. Peça um novo convite.';

/// Tela pública `/acesso/:token`: define a senha a partir do link de convite
/// ou de redefinição e entra no app.
class DefinirSenhaScreen extends StatefulWidget {
  const DefinirSenhaScreen({super.key, required this.token});

  final String token;

  @override
  State<DefinirSenhaScreen> createState() => _DefinirSenhaScreenState();
}

class _DefinirSenhaScreenState extends State<DefinirSenhaScreen> {
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();
  bool _obscure = true;
  bool _carregando = true;
  bool _enviando = false;
  bool _expirado = false;
  String? _erroCarga;
  String? _erroForm;
  String _tipo = 'CONVITE';
  String _primeiroNome = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarga = null;
    });
    try {
      final info = await context.read<AcessoService>().info(widget.token);
      if (!mounted) return;
      setState(() {
        _tipo = info.tipo;
        _primeiroNome = info.primeiroNome;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        if (e.status == 410) {
          _expirado = true;
        } else {
          _erroCarga = e.message;
        }
      });
    }
  }

  Future<void> _enviar() async {
    final senha = _senha.text;
    String? erro;
    if (senha.length < 8) {
      erro = 'A senha deve ter ao menos 8 caracteres.';
    } else if (senha.length > 100) {
      erro = 'A senha deve ter no máximo 100 caracteres.';
    } else if (senha != _confirmar.text) {
      erro = 'As senhas não coincidem.';
    }
    if (erro != null) {
      setState(() => _erroForm = erro);
      return;
    }
    setState(() {
      _erroForm = null;
      _enviando = true;
    });
    final acesso = context.read<AcessoService>();
    final auth = context.read<AuthProvider>();
    try {
      final login = await acesso.definirSenha(widget.token, senha);
      final ok = await auth.entrarComLogin(login);
      if (!mounted) return;
      if (ok) {
        context.go('/dashboard');
      } else {
        setState(() {
          _enviando = false;
          _erroForm = auth.error;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        if (e.status == 410) {
          _expirado = true;
        } else {
          _erroForm = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: _conteudo(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    final theme = Theme.of(context);
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_expirado) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_mensagemLinkExpirado, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ir para o login'),
          ),
        ],
      );
    }
    if (_erroCarga != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_erroCarga!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _carregar,
            child: const Text('Tentar de novo'),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Olá, $_primeiroNome', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          _tipo == 'REDEFINICAO' ? 'Crie uma nova senha' : 'Crie sua senha',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _senha,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Senha',
            helperText: 'Mínimo de 8 caracteres',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmar,
          obscureText: _obscure,
          decoration: const InputDecoration(labelText: 'Confirmar senha'),
          onSubmitted: (_) => _enviando ? null : _enviar(),
        ),
        if (_erroForm != null) ...[
          const SizedBox(height: 12),
          Text(_erroForm!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar senha'),
        ),
      ],
    );
  }
}
