import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/igreja_service.dart';
import '../../services/pessoa_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';

class IgrejasScreen extends StatefulWidget {
  const IgrejasScreen({super.key});

  @override
  State<IgrejasScreen> createState() => _IgrejasScreenState();
}

class _IgrejasScreenState extends State<IgrejasScreen> {
  List<Igreja> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      final items = await context.read<IgrejaService>().listVisiveis(user);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novaFilial() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isMatriz) return;
    Igreja? matriz;
    for (final i in _items) {
      if (i.isMatriz) matriz = i;
    }
    if (matriz == null) return;
    final pessoas = await context.read<PessoaService>().list(size: 100, igrejaId: matriz.id);
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => FilialFormDialog(pessoas: pessoas.content),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<IgrejaService>().createFilial(
            matrizId: matriz.id,
            nome: result['nome'] as String,
            pastorPessoaId: result['pastorPessoaId'] as String,
            pastorNome: result['pastorNome'] as String,
            adminNome: result['adminNome'] as String,
            adminEmail: result['adminEmail'] as String,
            adminUsername: result['adminUsername'] as String,
          );
      if (!mounted) return;
      await context.read<IgrejaContext>().reload(context.read<AuthProvider>().user);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Gestão Igreja',
          description: 'Matriz e filiais. Cada igreja tem um pastor e um admin.',
          actions: [
            if (context.watch<AuthProvider>().user?.isMatriz == true)
              FilledButton(onPressed: _novaFilial, child: const Text('Nova filial')),
          ],
        ),
        if (_loading)
          const LoadingView()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          ..._items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: i.nome,
                subtitle: 'Pastor: ${i.pastorNome} · Admin: ${i.adminNome}',
                trailing: StatusBadge(
                  label: igrejaTipoLabel(i.tipo).toUpperCase(),
                  success: i.isMatriz,
                ),
                onTap: () => context.push('/igrejas/${i.id}'),
                actions: [
                  OutlinedButton(
                    onPressed: () => context.push('/igrejas/${i.id}'),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
