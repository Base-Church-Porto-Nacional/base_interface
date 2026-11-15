import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/section_tabs_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/escala_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/escala_status_badge.dart';
import '../../widgets/filter_search.dart';

class ResponderEscalasScreen extends StatefulWidget {
  const ResponderEscalasScreen({super.key});

  @override
  State<ResponderEscalasScreen> createState() => _ResponderEscalasScreenState();
}

class _ResponderEscalasScreenState extends State<ResponderEscalasScreen> {
  List<Escala> _escalas = [];
  bool _loading = true;
  bool _actionLoading = false;
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
      final escalas = await context.read<EscalaService>().list(
            igrejaId: igrejaId,
            competencia: competenciaFrom(DateTime.now()),
            pessoaId: user?.pessoaId,
          );
      if (mounted) setState(() => _escalas = escalas);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<(Escala, EscalaVoluntario)> get _pendentes {
    final user = context.read<AuthProvider>().user;
    final result = <(Escala, EscalaVoluntario)>[];
    for (final e in _escalas) {
      if (e.status != EscalaStatus.emAndamento) continue;
      for (final v in e.voluntarios) {
        if (v.pessoaId != user?.pessoaId || v.status != EscalaItemStatus.pendente) {
          continue;
        }
        result.add((e, v));
      }
    }
    result.sort((a, b) => (a.$2.data ?? '').compareTo(b.$2.data ?? ''));
    return result;
  }

  List<(Escala, EscalaVoluntario)> get _respondidas {
    final user = context.read<AuthProvider>().user;
    final result = <(Escala, EscalaVoluntario)>[];
    for (final e in _escalas) {
      if (e.status != EscalaStatus.emAndamento) continue;
      for (final v in e.voluntarios) {
        if (v.pessoaId != user?.pessoaId || v.status == EscalaItemStatus.pendente) {
          continue;
        }
        result.add((e, v));
      }
    }
    result.sort((a, b) => (a.$2.data ?? '').compareTo(b.$2.data ?? ''));
    return result;
  }

  Future<void> _confirmar(Escala escala, EscalaVoluntario v) async {
    setState(() => _actionLoading = true);
    try {
      await context.read<EscalaService>().responderDesignacao(
            escala.id,
            v.id,
            status: EscalaItemStatus.confirmado,
          );
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _recusar(Escala escala, EscalaVoluntario v) async {
    final motivo = await _pedirMotivo();
    if (motivo == null || !mounted) return;
    final texto = motivo.trim();
    if (texto.isEmpty) {
      showSnack(context, 'Informe o motivo da recusa.');
      return;
    }
    setState(() => _actionLoading = true);
    try {
      await context.read<EscalaService>().responderDesignacao(
            escala.id,
            v.id,
            status: EscalaItemStatus.recusado,
            observacoes: texto,
          );
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<String?> _pedirMotivo() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar participação'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo da recusa *',
            hintText: 'Ex.: não estarei na cidade nesse fim de semana',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirmar recusa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTabs(
          currentPath: '/meu-servico/responder',
          tabs: meuServicoTabs,
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final pendentes = _pendentes;
    final respondidas = _respondidas;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
          title: 'Responder escalas',
          description:
              'Confirmar ou recusar participação nas escalas já lançadas (EM_ANDAMENTO).',
        ),
        if (pendentes.isEmpty && respondidas.isEmpty)
          const EmptyView(message: 'Nenhuma escala lançada aguardando sua resposta.'),
        if (pendentes.isNotEmpty) ...[
          Text(
            'Aguardando resposta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final (escala, v) in pendentes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: v.pessoaNome ?? 'Você',
                subtitle: [
                  escala.titulo,
                  if (v.servicoNome != null) v.servicoNome!,
                  if (v.data != null) formatDate(v.data!),
                ].join(' · '),
                trailing: EscalaItemStatusBadge(status: v.status),
                actions: [
                  TextButton.icon(
                    onPressed: _actionLoading
                        ? null
                        : () => _confirmar(escala, v),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirmar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _actionLoading
                        ? null
                        : () => _recusar(escala, v),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Recusar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (respondidas.isNotEmpty) ...[
          Text(
            'Respostas enviadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final (escala, v) in respondidas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: v.pessoaNome ?? 'Você',
                subtitle: [
                  escala.titulo,
                  if (v.servicoNome != null) v.servicoNome!,
                  if (v.data != null) formatDate(v.data!),
                ].join(' · '),
                trailing: EscalaItemStatusBadge(
                  status: v.status,
                  aprovadoPeloVoluntario: v.aprovadoPeloVoluntario,
                ),
              ),
            ),
        ],
      ],
    );
  }
}