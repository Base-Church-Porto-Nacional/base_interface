import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/igreja_context.dart';
import '../../services/pessoa_service.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class VoluntariosScreen extends StatefulWidget {
  const VoluntariosScreen({super.key});

  @override
  State<VoluntariosScreen> createState() => _VoluntariosScreenState();
}

class _VoluntariosScreenState extends State<VoluntariosScreen> {
  List<Pessoa> _items = [];
  String _search = '';
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  String? _loadedFor;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<PessoaService>().list(
            filtro: 'VOLUNTARIO',
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
          title: 'Voluntários',
          description: 'Pessoas vinculadas a serviços da igreja.',
        ),
        SearchField(
          hint: 'Buscar voluntário',
          onChanged: (v) {
            _search = v;
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 250), _load);
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
            child: Center(child: Text('Nenhum voluntário encontrado.')),
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
              ),
            ),
          ),
      ],
    );
  }
}
