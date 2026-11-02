import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_typography.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/brand/brand.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final message = auth.error;
      if (!mounted || message == null) return;
      auth.error = null;
      showSnack(context, message);
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_userController.text, _passController.text);
    if (!ok && mounted && auth.error != null) {
      showSnack(context, auth.error!);
    }
  }

  Widget _form(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final brand = context.brand;
    final theme = Theme.of(context);

    return GlassSurface(
      level: Elevation.e3,
      padding: const EdgeInsets.all(28),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandHeadline(
              'BEM-VINDO',
              style: AppTypography.hero.copyWith(color: brand.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Entre com sua conta',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: brand.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'Usuário'),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passController,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _wide(context);
          }
          return _narrow(context, constraints);
        },
      ),
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SpotlightBlock(
            child: _Lit(
              child: Stack(
                children: [
                  const Center(child: _Stage(size: 240, spinning: true)),
                  Positioned(
                    left: 40,
                    right: 40,
                    bottom: 40,
                    child: Text(
                      '2026 — A PARTIR DE JESUS',
                      style: AppTypography.eyebrow.copyWith(
                        color: context.brand.onInverse.withValues(alpha: 0.64),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AmbientBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _form(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context, BoxConstraints constraints) {
    const overlap = 48.0;
    final top = MediaQuery.paddingOf(context).top;
    final panel = (constraints.maxHeight * 0.4).clamp(280.0, 420.0);

    return AmbientBackground(
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: panel + top,
              child: SpotlightBlock(
                child: _Lit(
                  child: Padding(
                    padding: EdgeInsets.only(top: top, bottom: overlap / 2),
                    child: const Center(child: _Stage(size: 120)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                panel + top - overlap,
                20,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _form(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lit extends StatelessWidget {
  const _Lit({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final stage = theme.copyWith(
      brightness: Brightness.dark,
      extensions: [brand.copyWith(background: Colors.transparent)],
    );
    return Theme(
      data: stage,
      child: AmbientBackground(animated: true, child: child),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.size, this.spinning = false});

  final double size;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final onInverse = context.brand.onInverse;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: size * 2.2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  onInverse.withValues(alpha: 0.16),
                  onInverse.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.brand.inverse.withValues(alpha: 0.6),
                blurRadius: size * 0.35,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: SizedBox.square(dimension: size * 0.5),
        ),
        BrandSeal(size: size, spinning: spinning, color: onInverse),
      ],
    );
  }
}
