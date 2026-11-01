import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/cronograma_service.dart';
import '../../services/escala_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/escala_status_badge.dart';
import '../../widgets/filter_search.dart';

class MeuServicoScreen extends StatefulWidget {
  const MeuServicoScreen({super.key});

  @override
  State<MeuServicoScreen> createState() => _MeuServicoScreenState();
}

class _MeuServicoScreenState extends State<MeuServicoScreen> {
  List<CultoEvento> _eventos = [];
  List<Escala> _escalas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    final igrejaId = context.read<IgrejaContext>().selectedIgrejaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        context.read<CronogramaService>().list(igrejaId: igrejaId),
        context.read<EscalaService>().list(igrejaId: igrejaId, pessoaId: user?.pessoaId),
      ]);
      if (mounted) {
        setState(() {
          _eventos = results[0] as List<CultoEvento>;
          _escalas = results[1] as List<Escala>;
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
    return Column(
      children: [
        const SectionTabs(
          currentPath: '/meu-servico',
          tabs: meuServicoTabs,
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final proximos = _eventos.take(5).toList();
    final escalasComDesignacoes = _escalas
        .where((e) => e.voluntarios.isNotEmpty || e.itens.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
          title: 'Meu serviço',
          description: 'Eventos, cultos e as escalas em que você está.',
        ),
        Text(
          'Próximos cultos e eventos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (proximos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Nenhum evento no período.'),
          )
        else
          for (final e in proximos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: e.titulo,
                subtitle:
                    '${formatDate(e.data)} · ${e.horaInicio} · ${tipoEventoLabel(e.tipo)}',
              ),
            ),
        const SizedBox(height: 8),
        Text('Minhas escalas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (escalasComDesignacoes.isEmpty)
          const Text('Você ainda não está em nenhuma escala.')
        else
          for (final e in escalasComDesignacoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EscalaCard(escala: e),
            ),
      ],
    );
  }
}

class _EscalaCard extends StatelessWidget {
  const _EscalaCard({required this.escala});

  final Escala escala;

  @override
  Widget build(BuildContext context) {
    final escalaName = escala.titulo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            escalaName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final v in escala.voluntarios)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MobileListTile(
              title: v.servicoNome ?? 'Designação',
              subtitle: [
                if (v.data != null) formatDate(v.data!),
                escalaStatusLabel(escala.status),
              ].join(' · '),
              trailing: EscalaItemStatusBadge(
                status: v.status,
                aprovadoPeloVoluntario: v.aprovadoPeloVoluntario,
              ),
            ),
          ),
        for (final i in escala.itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MobileListTile(
              title: i.servicoNome ?? 'Designação',
              subtitle: [
                if (i.data.isNotEmpty) formatDate(i.data),
                escalaStatusLabel(escala.status),
              ].join(' · '),
              trailing: EscalaItemStatusBadge(status: i.status),
            ),
          ),
      ],
    );
  }
}
