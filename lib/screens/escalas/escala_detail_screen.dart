import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/escala_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/escala_status_badge.dart';

class EscalaDetailScreen extends StatefulWidget {
  const EscalaDetailScreen({super.key, required this.escalaId});

  final String escalaId;

  @override
  State<EscalaDetailScreen> createState() => _EscalaDetailScreenState();
}

class _EscalaDetailScreenState extends State<EscalaDetailScreen> {
  Escala? _escala;
  bool _loading = true;
  bool _actionLoading = false;
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
      final escala = await context.read<EscalaService>().getById(widget.escalaId);
      if (mounted) setState(() => _escala = escala);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmarTransicao(EscalaStatus para, String titulo, String corpo) async {
    final ok = await confirmDialog(
      context,
      title: titulo,
      message: corpo,
    );
    if (!ok) return;
    if (!mounted) return;
    setState(() => _actionLoading = true);
    try {
      await context.read<EscalaService>().updateStatus(widget.escalaId, para);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _gerarSugestoes() async {
    setState(() => _actionLoading = true);
    try {
      final resultado = await context.read<EscalaService>().gerarSugestoes(widget.escalaId);
      await _load();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sugestões geradas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resultado.message),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Status: '),
                  StatusBadge(
                    label: resultado.status,
                    success: resultado.status == 'COMPLETA',
                  ),
                ],
              ),
              if (resultado.sugestoes.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in resultado.sugestoes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: MobileListTile(
                            title: s.pessoaNome ?? '—',
                            subtitle: '${s.servicoNome ?? ''}${s.data != null ? ' · ${formatDate(s.data!)}' : ''}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir escala',
      message: 'Deseja excluir esta escala? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      await context.read<EscalaService>().delete(widget.escalaId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showSnack(context, e);
        setState(() => _actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _escala == null) {
      return ErrorView(message: _error ?? 'Escala não encontrada.', onRetry: _load);
    }
    final e = _escala!;
    final user = context.watch<AuthProvider>().user;
    final podeEditar = podeEditarEscala(user, _escala);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: e.titulo,
          description: '${escalaTipoLabel(e.tipo)} · ${formatCompetencia(e.competencia)}',
          actions: [
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
            if (podeEditar)
              FilledButton(
                onPressed: e.status == EscalaStatus.finalizada || _actionLoading
                    ? null
                    : () => context.push('/voluntariado/escalas/${e.id}/editar'),
                child: const Text('Editar'),
              ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: escalaStatusLabel(e.status).toUpperCase(),
                      success: e.status == EscalaStatus.finalizada,
                    ),
                    if (e.geraAuto())
                      const StatusBadge(label: 'RECOMENDADA PELA AUTOMAÇÃO', success: true),
                  ],
                ),
                const SizedBox(height: 12),
                _row('Competência', formatCompetencia(e.competencia)),
                _row('Tipo', escalaTipoLabel(e.tipo)),
                if (e.ministerioNome != null) _row('Ministério', e.ministerioNome!),
                _row('Supervisor', e.supervisorNome),
                if (e.pregadorNome != null) _row('Pregador', e.pregadorNome!),
                if (e.descricao != null && e.descricao!.isNotEmpty) _row('Descrição', e.descricao!),
                if (e.dataEvento != null) _row('Evento', formatDate(e.dataEvento!)),
                if (e.horaInicio != null)
                  _row('Horário', '${e.horaInicio}${e.horaFim != null ? ' às ${e.horaFim}' : ''}'),
                if (e.dataLancamento != null) _row('Lançada em', e.dataLancamento!),
                if (e.dataFinalizacao != null) _row('Finalizada em', e.dataFinalizacao!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (podeEditar) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (e.status == EscalaStatus.sugerida || e.status == EscalaStatus.editando)
                OutlinedButton.icon(
                  onPressed: _actionLoading
                      ? null
                      : () => _confirmarTransicao(
                            EscalaStatus.emAndamento,
                            'Lançar escala',
                            'Ao lançar (EM_ANDAMENTO) a escala fica publicada e grava a data de lançamento.',
                          ),
                  icon: const Icon(Icons.published_with_changes, size: 18),
                  label: const Text('Lançar escala'),
                ),
              if (e.status == EscalaStatus.emAndamento)
                OutlinedButton.icon(
                  onPressed: _actionLoading
                      ? null
                      : () => _confirmarTransicao(
                            EscalaStatus.finalizada,
                            'Finalizar escala',
                            'Ao finalizar (FINALIZADA) a escala grava a data de finalização.',
                          ),
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text('Finalizar'),
                ),
              OutlinedButton.icon(
                onPressed: _actionLoading || e.servicos.isEmpty ? null : _gerarSugestoes,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Gerar sugestões'),
              ),
              if (e.status == EscalaStatus.emAndamento)
                OutlinedButton.icon(
                  onPressed: _actionLoading
                      ? null
                      : () => _confirmarTransicao(
                            EscalaStatus.editando,
                            'Edição pós-lançamento',
                            'A escala voltará para EDITANDO. Você poderá ajustar designações e lançar novamente.',
                          ),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Voltar para edição'),
                ),
              OutlinedButton.icon(
                onPressed: _actionLoading ? null : _excluir,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Excluir'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text('Serviços necessários', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (e.servicos.isEmpty)
          const Text('Nenhum serviço nesta escala.')
        else
          for (final s in e.servicos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: s.servicoNome ?? 'Serviço',
                subtitle: '${s.quantidadeNecessaria} vaga(s) · ${e.preenchidosDoServico(s.servicoId)} preenchida(s)',
              ),
            ),
        const SizedBox(height: 16),
        Text('Voluntários designados', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (e.voluntarios.isEmpty)
          const Text('Nenhum voluntário designado.')
        else
          for (final v in e.voluntarios)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: v.pessoaNome ?? '—',
                subtitle: [
                  if (v.servicoNome != null) v.servicoNome!,
                  if (v.data != null) formatDate(v.data!),
                ].join(' · '),
                trailing: EscalaItemStatusBadge(
                  status: v.status,
                  aprovadoPeloVoluntario: v.aprovadoPeloVoluntario,
                ),
              ),
            ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}