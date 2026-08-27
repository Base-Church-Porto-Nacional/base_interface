import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/igreja_context.dart';
import '../../services/export_service.dart';
import '../../services/pessoa_service.dart';
import '../../widgets/common.dart';
import '../../widgets/export_menu.dart';
import '../../widgets/filter_search.dart';

class LideresScreen extends StatefulWidget {
  const LideresScreen({super.key});

  @override
  State<LideresScreen> createState() => _LideresScreenState();
}

class _LideresScreenState extends State<LideresScreen> {
  List<Pessoa> _items = [];
  String _search = '';
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<PessoaService>().list(
            filtro: 'LIDER',
            search: _search,
            size: 50,
            igrejaId: context.read<IgrejaContext>().selectedIgrejaId,
          );
      if (mounted) setState(() => _items = response.content);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Líderes',
          description: 'Voluntários com papel de liderança.',
          actions: const [ExportMenu(recurso: ExportRecurso.lideres)],
        ),
        SearchField(
          hint: 'Buscar líder',
          onChanged: (v) {
            _search = v;
            _scheduleLoad();
          },
        ),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingView()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Nenhum líder encontrado.')),
          )
        else
          ..._items.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: p.nome,
                subtitle: p.ministerios.join(', '),
                trailing: StatusBadge(
                  label: pessoaStatusLabel(p.status),
                  success: p.status == PessoaStatus.ativo,
                ),
                onTap: () => context.push('/membros/pessoa/${p.id}'),
                actions: [
                  OutlinedButton(
                    onPressed: () => context.push('/membros/pessoa/${p.id}'),
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
