import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/igreja_context.dart';
import '../../services/cronograma_service.dart';
import '../../services/pessoa_service.dart';
import '../../utils/format.dart';
import '../../utils/route_access.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class CronogramaScreen extends StatefulWidget {
  const CronogramaScreen({super.key});

  @override
  State<CronogramaScreen> createState() => _CronogramaScreenState();
}

class _CronogramaScreenState extends State<CronogramaScreen> {
  List<CultoEvento> _items = [];
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
      final items = await context.read<CronogramaService>().list(igrejaId: igrejaId);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novo() async {
    if (!canCreateCronograma(context.read<AuthProvider>().user)) return;
    final igreja = context.read<IgrejaContext>().selected;
    if (igreja == null) return;
    final pessoas = await context.read<PessoaService>().list(size: 100, igrejaId: igreja.id);
    if (!mounted) return;

    final titulo = TextEditingController(text: 'Culto de domingo');
    var tipo = TipoEvento.culto;
    final hoje = DateTime.now();
    var data = DateTime(hoje.year, hoje.month, hoje.day);
    final hora = TextEditingController(text: '18:00');
    final local = TextEditingController();
    var supervisorId = igreja.pastorPessoaId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Novo culto / evento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titulo,
                      decoration: const InputDecoration(labelText: 'Título *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TipoEvento>(
                      value: tipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: [
                        for (final t in TipoEvento.values)
                          DropdownMenuItem(value: t, child: Text(tipoEventoLabel(t))),
                      ],
                      onChanged: (v) => setLocal(() => tipo = v ?? tipo),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data'),
                      subtitle: Text(formatDate(isoDate(data))),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: data,
                          firstDate: DateTime(hoje.year - 1),
                          lastDate: DateTime(hoje.year + 3),
                        );
                        if (picked != null) setLocal(() => data = picked);
                      },
                    ),
                    TextField(
                      controller: hora,
                      decoration: const InputDecoration(labelText: 'Horário'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: local,
                      decoration: const InputDecoration(labelText: 'Local'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: supervisorId,
                      decoration: const InputDecoration(
                        labelText: 'Supervisor',
                        helperText: 'Padrão: pastor da igreja',
                      ),
                      items: [
                        for (final p in pessoas.content)
                          DropdownMenuItem(value: p.id, child: Text(p.nome)),
                      ],
                      onChanged: (v) => setLocal(() => supervisorId = v ?? supervisorId),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    Pessoa? supervisor;
    for (final p in pessoas.content) {
      if (p.id == supervisorId) supervisor = p;
    }
    try {
      await context.read<CronogramaService>().create(
            CultoEvento(
              id: '',
              titulo: titulo.text.trim(),
              tipo: tipo,
              data: isoDate(data),
              horaInicio: hora.text.trim(),
              localEvento: local.text.trim().isEmpty ? null : local.text.trim(),
              igrejaId: igreja.id,
              supervisorPessoaId: supervisor?.id ?? igreja.pastorPessoaId,
              supervisorNome: supervisor?.nome ?? igreja.pastorNome,
              ativo: true,
            ),
          );
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
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
    final canCreate = canCreateCronograma(context.watch<AuthProvider>().user);

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/cultos',
          tabs: cultosAgendaTabs,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PageHeader(
                title: 'Agenda',
                description:
                    'Cultos e eventos da igreja. Cada um tem um supervisor (padrão: pastor).',
                actions: [
                  if (canCreate) FilledButton(onPressed: _novo, child: const Text('Novo')),
                ],
              ),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else if (_items.isEmpty)
                const EmptyView(message: 'Nenhum culto ou evento.')
              else
                ..._items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MobileListTile(
                      title: e.titulo,
                      subtitle:
                          '${formatDate(e.data)} · ${e.horaInicio} · Supervisor: ${e.supervisorNome}',
                      trailing: StatusBadge(label: tipoEventoLabel(e.tipo).toUpperCase()),
                      onTap: e.tipo == TipoEvento.culto
                          ? () => context.push('/cultos/conteudo?eventoId=${e.id}')
                          : null,
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
