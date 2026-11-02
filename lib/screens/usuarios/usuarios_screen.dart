import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/igreja_context.dart';
import '../../services/usuario_service.dart';
import '../../widgets/common.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<UsuarioConta> _items = [];
  bool _loading = true;
  String? _error;
  String? _loadedFor;

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<UsuarioService>().list(igrejaId: igrejaId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final igrejaId = context.watch<IgrejaContext>().selectedIgrejaId;
    if (igrejaId != _loadedFor) {
      _loadedFor = igrejaId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
          title: 'Usuários',
          description: 'Contas de acesso da igreja visível. Crie a partir da ficha da pessoa.',
        ),
        if (_loading)
          const LoadingView()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Nenhum usuário nesta igreja.')),
          )
        else
          ..._items.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: u.pessoaNome ?? (u.email.isNotEmpty ? u.email : (u.telefone ?? '—')),
                subtitle:
                    '${[u.email, u.telefone].where((c) => c != null && c.isNotEmpty).join(' · ')} · ${u.papeis.map(papelLabel).join(', ')} · ${u.igrejaNome}',
                trailing: StatusBadge(label: u.ativo ? 'ATIVO' : 'INATIVO', success: u.ativo),
                onTap: u.pessoaId == null
                    ? null
                    : () => context.push('/membros/pessoa/${u.pessoaId}'),
              ),
            ),
          ),
      ],
    );
  }
}
