import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/export_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/route_access.dart';
import '../../widgets/common.dart';
import '../../widgets/export_menu.dart';
import '../../widgets/filter_search.dart';
import '../../widgets/form_dialogs.dart';

class MembrosScreen extends StatefulWidget {
  const MembrosScreen({super.key});

  @override
  State<MembrosScreen> createState() => _MembrosScreenState();
}

class _MembrosScreenState extends State<MembrosScreen> {
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
            filtro: 'MEMBRO',
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

  Future<void> _openForm([Pessoa? editing]) async {
    if (!canMutatePessoas(context.read<AuthProvider>().user)) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => PessoaFormDialog(
        title: editing == null ? 'Novo membro' : 'Editar membro',
        initialNome: editing?.nome ?? '',
        initialTelefone: editing?.telefone ?? '',
        initialEmail: editing?.email ?? '',
        initialWhatsapp: editing?.whatsapp ?? '',
      ),
    );
    if (result == null || !mounted) return;

    try {
      final service = context.read<PessoaService>();
      if (editing == null) {
        final created = await service.create(
          nome: result['nome']!,
          telefone: result['telefone'],
          email: result['email'],
          whatsapp: result['whatsapp'],
          igrejaId: context.read<IgrejaContext>().selectedIgrejaId,
        );
        if (mounted) context.push('/membros/pessoa/${created.id}');
      } else {
        await service.update(
          editing.id,
          nome: result['nome']!,
          telefone: result['telefone'],
          email: result['email'],
          whatsapp: result['whatsapp'],
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final podeMutar = canMutatePessoas(context.watch<AuthProvider>().user);
    return Column(
      children: [
        SectionTabs(
          currentPath: '/membros',
          tabs: const [
            ('/membros', 'Membros'),
            ('/membros/pessoas', 'Pessoas'),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Membros',
                description: 'Pessoas com vínculo de membro na igreja.',
                actions: [
                  const ExportMenu(recurso: ExportRecurso.membros),
                  if (podeMutar)
                    FilledButton(onPressed: () => _openForm(), child: const Text('Novo')),
                ],
              ),
              SearchField(
                hint: 'Buscar membro',
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
                  child: Center(child: Text('Nenhum membro encontrado.')),
                )
              else
                ..._items.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileListTile(
                      title: p.nome,
                      subtitle: p.ministerios.isNotEmpty
                          ? p.ministerios.join(', ')
                          : pessoaStatusLabel(p.status),
                      badges: p.papeisExibiveis.map(roleLabel).toList(),
                      trailing: StatusBadge(
                        label: pessoaStatusLabel(p.status),
                        success: p.status == PessoaStatus.ativo,
                      ),
                      onTap: () => context.push('/membros/pessoa/${p.id}'),
                      actions: [
                        OutlinedButton(
                          onPressed: () => _openForm(p),
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
