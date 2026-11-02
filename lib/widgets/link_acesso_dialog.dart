import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mostra o link de acesso (convite ou redefinição) para copiar e enviar.
class LinkAcessoDialog extends StatelessWidget {
  const LinkAcessoDialog({
    super.key,
    required this.link,
    required this.enviadoWhatsapp,
    this.titulo = 'Link de acesso',
  });

  final String link;
  final bool enviadoWhatsapp;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            enviadoWhatsapp ? 'Enviamos pelo WhatsApp.' : 'Não foi possível enviar pelo WhatsApp. Copie o link e envie para a pessoa.',
          ),
          const SizedBox(height: 12),
          SelectableText(link, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        FilledButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: link));
            messenger.showSnackBar(
              const SnackBar(content: Text('Link copiado')),
            );
          },
          child: const Text('Copiar link'),
        ),
      ],
    );
  }
}
