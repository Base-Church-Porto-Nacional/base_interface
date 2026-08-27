import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/cronograma_service.dart';
import '../../services/escala_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

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
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final proximos = _eventos.take(5).toList();
    final itens = <EscalaItem>[];
    for (final e in _escalas) {
      itens.addAll(e.itens);
    }
    itens.sort((a, b) => a.data.compareTo(b.data));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Meu serviço',
          description: 'Eventos, cultos e as escalas em que você está.',
          actions: [
            OutlinedButton(
              onPressed: () => context.push('/perfil/disponibilidade'),
              child: const Text('Disponibilidade'),
            ),
          ],
        ),
        Text('Próximos cultos e eventos', style: Theme.of(context).textTheme.titleMedium),
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
                subtitle: '${formatDate(e.data)} · ${e.horaInicio} · ${tipoEventoLabel(e.tipo)}',
              ),
            ),
        const SizedBox(height: 8),
        Text('Minhas escalas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (itens.isEmpty)
          const Text('Você ainda não está em nenhuma escala.')
        else
          for (final item in itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: item.pessoaNome ?? 'Você',
                subtitle:
                    '${formatDate(item.data)}${item.servicoNome != null ? ' · ${item.servicoNome}' : ''}',
                trailing: StatusBadge(
                  label: item.status.name.toUpperCase(),
                  success: item.status == EscalaItemStatus.confirmado,
                ),
              ),
            ),
      ],
    );
  }
}
