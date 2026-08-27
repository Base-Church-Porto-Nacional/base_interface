import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AcessoNegadoScreen extends StatelessWidget {
  const AcessoNegadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Acesso negado', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Você não tem permissão para esta área.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}
