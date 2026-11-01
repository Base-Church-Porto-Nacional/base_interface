import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import 'dashboard_service.dart';
import 'pessoa_service.dart';

enum ExportFormato { txt, md, xlsx }

enum ExportRecurso { pessoas, membros, lideres, dashboard, ministerios }

class ExportOpcoes {
  const ExportOpcoes({this.filtro, this.incluirHistorico = false});

  final String? filtro;
  final bool incluirHistorico;
}

class ExportService {
  ExportService(this._pessoaService, this._dashboardService);

  final PessoaService _pessoaService;
  final DashboardService _dashboardService;

  Future<void> share(
    ExportRecurso recurso,
    ExportFormato formato, {
    ExportOpcoes opcoes = const ExportOpcoes(),
  }) async {
    final content = await _buildContent(recurso, formato, opcoes);
    final ext = formato.name;
    await SharePlus.instance.share(
      ShareParams(text: content, subject: '${recurso.name}.$ext'),
    );
  }

  Future<String> _buildContent(
    ExportRecurso recurso,
    ExportFormato formato,
    ExportOpcoes opcoes,
  ) async {
    final incluirHistorico = opcoes.incluirHistorico;
    final filtro =
        opcoes.filtro ??
        switch (recurso) {
          ExportRecurso.membros => 'MEMBRO',
          ExportRecurso.lideres => 'LIDER',
          _ => null,
        };


    if (recurso == ExportRecurso.dashboard) {
      final stats = await _dashboardService.getStats();
      if (stats == null) return 'Dashboard indisponível para o seu perfil.';
      return _exportDashboard(stats, formato);
    }

    if (recurso == ExportRecurso.pessoas ||
        recurso == ExportRecurso.membros ||
        recurso == ExportRecurso.lideres) {
      final response = await _pessoaService.list(
        filtro: filtro ?? 'TODOS',
        size: 500,
      );
      final titulo = switch (recurso) {
        ExportRecurso.membros => 'Membros',
        ExportRecurso.lideres => 'Líderes',
        _ => 'Pessoas',
      };
      return await _exportPessoas(
        response.content,
        formato,
        titulo,
        incluirHistorico,
      );
    }

    // Fallback API download não implementado no mobile — retorna placeholder
    return 'Exportação ${recurso.name} (${formato.name})';
  }

  Future<String> _exportPessoas(
    List<Pessoa> pessoas,
    ExportFormato formato,
    String titulo,
    bool incluirHistorico,
  ) async {
    final rows = <String>[];
    for (final p in pessoas) {
      final tipos = p.tipos.map((t) => t.name.toUpperCase()).join(', ');
      final base = formato == ExportFormato.md
          ? '- **${p.nome}** — ${p.telefone} · ${p.email} · $tipos'
          : '${p.nome}\t${p.telefone}\t${p.email}\t$tipos';
      if (!incluirHistorico) {
        rows.add(base);
        continue;
      }
      final historico = await _pessoaService.listHistorico(p.id);
      rows.add('$base\n${_linhasHistorico(historico)}');
    }

    if (formato == ExportFormato.md) {
      return '# $titulo\n\n${rows.join('\n\n')}\n';
    }
    return '$titulo\n\n${rows.join('\n\n')}\n';
  }

  String _linhasHistorico(List<PessoaHistorico> items) {
    if (items.isEmpty) return '  Histórico: (vazio)';
    return [
      '  Histórico:',
      ...items.map(
        (h) =>
            '  - ${h.dataRegistro} · ${h.descricao} (${h.autorNome}${h.autorCargo != null ? ', ${h.autorCargo}' : ''})',
      ),
    ].join('\n');
  }

  String _exportDashboard(DashboardStats stats, ExportFormato formato) {
    final jornada = stats.jornada;
    final lines = [
      'Pessoas: ${stats.totalPessoas}',
      'Membros: ${stats.totalMembros}',
      'Voluntários: ${stats.totalVoluntarios}',
      'Líderes: ${stats.totalLideres}',
      if (stats.escalasPendentes != null)
        'Escalas pendentes: ${stats.escalasPendentes}',
      if (stats.visitantesRecentes != null)
        'Visitantes recentes: ${stats.visitantesRecentes}',
      if (jornada != null) ...[
        'Novos visitantes: ${jornada.novosVisitantes}',
        'Aceitaram Jesus: ${jornada.aceitaramJesus}',
        'Batizados: ${jornada.batizados}',
        'Trilha da Base: ${jornada.trilhaBase}',
        'Novos membros: ${jornada.novosMembros}',
      ],
    ];
    if (formato == ExportFormato.md) {
      return '# Dashboard\n\n${lines.map((l) => '- $l').join('\n')}\n';
    }
    return 'Dashboard\n\n${lines.join('\n')}\n';
  }
}
