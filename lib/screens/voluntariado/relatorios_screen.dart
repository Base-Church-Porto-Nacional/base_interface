import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/igreja_context.dart';
import '../../services/base_ministerial_service.dart';
import '../../services/escala_service.dart';
import '../../services/ministerio_service.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  List<Escala> _escalas = [];
  List<Ministerio> _ministerios = [];
  List<BaseMinisterial> _bases = [];
  bool _loading = true;
  String? _error;
  String? _loadedFor;

  Future<void> _load() async {
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    final escalaService = context.read<EscalaService>();
    final ministerioService = context.read<MinisterioService>();
    final baseMinisterialService = context.read<BaseMinisterialService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final escalas = await escalaService.list(igrejaId: igrejaId);
      final ministerios = await ministerioService.list(igrejaId: igrejaId);
      final bases = await baseMinisterialService.list(igrejaId: igrejaId);
      if (mounted) {
        setState(() {
          _escalas = escalas;
          _ministerios = ministerios;
          _bases = bases;
        });
      }
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

    return Column(
      children: [
        const SectionTabs(
          currentPath: '/voluntariado/relatorios',
          tabs: [
            ('/voluntariado/voluntarios', 'Voluntários'),
            ('/voluntariado/escalas', 'Escalas'),
            ('/voluntariado/ministerios', 'Ministérios'),
            ('/voluntariado/relatorios', 'Relatórios'),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(
                title: 'Relatórios',
                description: 'Presença, serviços realizados e voluntários por ministério e base.',
              ),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                ErrorView(message: _error!, onRetry: _load)
              else ...[
                _presencaSection(),
                const SizedBox(height: 16),
                _historicoServicosSection(),
                const SizedBox(height: 16),
                _voluntariosSection(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _presencaSection() {
    final porMinisterio = <String, Map<EscalaItemStatus, int>>{};
    for (final escala in _escalas) {
      final chave = escala.ministerioNome ?? escala.titulo;
      final contagem = porMinisterio.putIfAbsent(chave, () => {
            for (final s in EscalaItemStatus.values) s: 0,
          });
      for (final item in escala.itens) {
        contagem[item.status] = (contagem[item.status] ?? 0) + 1;
      }
    }

    return _SectionCard(
      title: 'Presença e participação em escalas',
      empty: porMinisterio.isEmpty,
      children: [
        for (final entry in porMinisterio.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in EscalaItemStatus.values)
                      StatusBadge(
                        label: '${_statusLabel(status)}: ${entry.value[status] ?? 0}',
                        success: status == EscalaItemStatus.confirmado,
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _historicoServicosSection() {
    final porServico = <String, int>{};
    for (final escala in _escalas) {
      for (final item in escala.itens) {
        if (item.status != EscalaItemStatus.confirmado) continue;
        final chave = item.servicoNome ?? 'Serviço';
        porServico[chave] = (porServico[chave] ?? 0) + 1;
      }
    }
    final entries = porServico.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _SectionCard(
      title: 'Histórico de serviços realizados',
      empty: entries.isEmpty,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MobileListTile(
              title: entry.key,
              subtitle: '${entry.value} serviço(s) confirmado(s)',
            ),
          ),
      ],
    );
  }

  Widget _voluntariosSection() {
    final porBase = <String, int>{};
    for (final base in _bases) {
      porBase[base.nome] = 0;
    }
    var semBase = 0;
    for (final ministerio in _ministerios) {
      BaseMinisterial? base;
      for (final b in _bases) {
        if (b.id == ministerio.baseMinisterialId) {
          base = b;
          break;
        }
      }
      if (base == null) {
        semBase += ministerio.totalVoluntarios;
      } else {
        porBase[base.nome] = (porBase[base.nome] ?? 0) + ministerio.totalVoluntarios;
      }
    }

    return _SectionCard(
      title: 'Voluntários por ministério e base',
      empty: _ministerios.isEmpty,
      children: [
        Text('Por base ministerial', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final entry in porBase.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MobileListTile(title: entry.key, subtitle: '${entry.value} voluntário(s)'),
          ),
        if (semBase > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MobileListTile(title: 'Sem base', subtitle: '$semBase voluntário(s)'),
          ),
        const SizedBox(height: 12),
        Text('Por ministério', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final m in _ministerios)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MobileListTile(title: m.nome, subtitle: '${m.totalVoluntarios} voluntário(s)'),
          ),
      ],
    );
  }

  String _statusLabel(EscalaItemStatus status) {
    switch (status) {
      case EscalaItemStatus.pendente:
        return 'Pendente';
      case EscalaItemStatus.confirmado:
        return 'Confirmado';
      case EscalaItemStatus.recusado:
        return 'Recusado';
      case EscalaItemStatus.substituido:
        return 'Substituído';
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children, required this.empty});

  final String title;
  final List<Widget> children;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (empty) const Text('Sem dados para exibir.') else ...children,
          ],
        ),
      ),
    );
  }
}
