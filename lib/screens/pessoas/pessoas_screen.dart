import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/nav_config.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/export_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/route_access.dart';
import '../../widgets/common.dart';
import '../../widgets/export_menu.dart';
import '../../widgets/filter_search.dart';
import '../../widgets/form_dialogs.dart';

class PessoasScreen extends StatefulWidget {
  const PessoasScreen({super.key});

  @override
  State<PessoasScreen> createState() => _PessoasScreenState();
}

class _PessoasScreenState extends State<PessoasScreen> {
  List<Pessoa> _items = [];
  int _totalPages = 1;
  int _page = 0;
  String _search = '';
  String _filtro = 'TODOS';
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
      final response = await context.read<PessoaService>().list(
            page: _page,
            size: 10,
            search: _search,
            filtro: _filtro,
            igrejaId: context.read<IgrejaContext>().selectedIgrejaId,
          );
      if (mounted) {
        setState(() {
          _items = response.content;
          _totalPages = response.totalPages;
        });
      }
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
        title: editing == null ? 'Nova pessoa' : 'Editar pessoa',
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
        await service.create(
          nome: result['nome']!,
          telefone: result['telefone'],
          email: result['email'],
          whatsapp: result['whatsapp'],
          igrejaId: context.read<IgrejaContext>().selectedIgrejaId,
        );
      } else {
        await service.update(
          editing.id,
          nome: result['nome']!,
          telefone: result['telefone'],
          email: result['email'],
          whatsapp: result['whatsapp'],
        );
      }
      if (mounted) {
        showSnack(context, editing == null ? 'Pessoa criada.' : 'Pessoa atualizada.');
        _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, e);
    }
  }

  String _filtroLabel() {
    for (final (value, label) in pessoaFiltros) {
      if (value == _filtro) return label;
    }
    return 'Todos';
  }

  @override
  Widget build(BuildContext context) {
    final podeMutar = canMutatePessoas(context.watch<AuthProvider>().user);
    return Column(
      children: [
        const SectionTabs(
          currentPath: '/membros/pessoas',
          tabs: membrosTabs,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Pessoas',
                description: 'Cadastro geral — visitantes, membros e voluntários.',
                actions: [
                  ExportMenu(
                    recurso: ExportRecurso.pessoas,
                    filtro: _filtro == 'TODOS' ? null : _filtro,
                    allowHistorico: true,
                  ),
                  if (podeMutar)
                    FilledButton(
                      onPressed: () => _openForm(),
                      child: const Text('Nova'),
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      hint: 'Buscar nome, e-mail ou telefone',
                      onChanged: (v) {
                        _search = v;
                        _page = 0;
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterMenu(
                    value: _filtro,
                    onChanged: (v) {
                      setState(() => _filtro = v);
                      _page = 0;
                      _load();
                    },
                  ),
                ],
              ),
              if (_filtro != 'TODOS') ...[
                const SizedBox(height: 8),
                Text('Filtro: ${_filtroLabel()}', style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (_items.isEmpty)
                const EmptyView(message: 'Nenhuma pessoa encontrada.')
              else
                ..._items.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileListTile(
                      title: p.nome,
                      subtitle: [
                        if (p.ministerios.isNotEmpty) p.ministerios.join(', '),
                        pessoaStatusLabel(p.status),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      badges: p.papeis.map(roleLabel).toList(),
                      onTap: () => context.push('/membros/pessoa/${p.id}'),
                      actions: [
                        if (podeMutar)
                          OutlinedButton(
                            onPressed: () => _openForm(p),
                            child: const Text('Editar'),
                          ),
                      ],
                    ),
                  ),
                ),
              if (!_loading && _totalPages > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _page > 0
                          ? () {
                              _page--;
                              _load();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${_page + 1} / $_totalPages'),
                    IconButton(
                      onPressed: _page < _totalPages - 1
                          ? () {
                              _page++;
                              _load();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
