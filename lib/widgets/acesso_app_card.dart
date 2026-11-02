import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/usuario_service.dart';
import '../utils/route_access.dart';
import 'common.dart';
import 'link_acesso_dialog.dart';

String acessoStatusLabel(String? status) => switch (status) {
  'CONVIDADO' => 'Convite pendente',
  'ATIVO' => 'Ativo',
  'DESATIVADO' => 'Desativado',
  _ => 'Sem acesso',
};

/// Bloco "Acesso ao app" do detalhe da pessoa: status da conta e ações
/// (convidar, reenviar, redefinir senha, desativar, reativar, papéis).
/// [onAlterado] é chamado depois de qualquer ação concluída.
class AcessoAppCard extends StatefulWidget {
  const AcessoAppCard({
    super.key,
    required this.pessoa,
    required this.user,
    required this.onAlterado,
    this.onPapeis,
  });

  final Pessoa pessoa;
  final AuthUser? user;
  final VoidCallback onAlterado;

  /// Abre o diálogo de papéis (Fase 1); null esconde o botão.
  final VoidCallback? onPapeis;

  @override
  State<AcessoAppCard> createState() => _AcessoAppCardState();
}

class _AcessoAppCardState extends State<AcessoAppCard> {
  bool _ocupado = false;

  Future<void> _executar(
    Future<void> Function(UsuarioService service) acao, {
    String? sucesso,
  }) async {
    final service = context.read<UsuarioService>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      await acao(service);
      if (!mounted) return;
      if (sucesso != null) {
        messenger.showSnackBar(SnackBar(content: Text(sucesso)));
      }
      widget.onAlterado();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _mostrarLink(LinkAcesso r, String titulo) {
    return showDialog<void>(
      context: context,
      builder: (_) => LinkAcessoDialog(
        link: r.link,
        enviadoWhatsapp: r.enviadoWhatsapp,
        titulo: titulo,
      ),
    );
  }

  Future<void> _convidar({required bool reenvio}) => _executar((s) async {
    final r = await s.convidar(widget.pessoa.id);
    if (!mounted) return;
    await _mostrarLink(r, reenvio ? 'Convite reenviado' : 'Convite criado');
  });

  Future<void> _redefinir() => _executar((s) async {
    final r = await s.gerarRedefinicao(widget.pessoa.usuarioId!);
    if (!mounted) return;
    await _mostrarLink(r, 'Redefinição de senha');
  });

  Future<void> _desativar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Desativar acesso de ${widget.pessoa.nome}?'),
        content: const Text(
          'A pessoa deixa de conseguir entrar no app até ser reativada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _executar(
      (s) => s.desativar(widget.pessoa.usuarioId!),
      sucesso: 'Acesso desativado.',
    );
  }

  Future<void> _reativar() => _executar(
    (s) => s.reativar(widget.pessoa.usuarioId!),
    sucesso: 'Acesso reativado.',
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.pessoa;
    final status = p.acessoStatus;
    final convidar = podeConvidar(widget.user);
    // Conta de pastor/secretaria: só quem atribui esses papéis (pastor) mexe
    // em senha e acesso — o servidor responde 403 para os demais.
    final contaDeGestao =
        p.tipos.contains(PessoaTipo.pastor) ||
        p.papeis.contains('PASTOR') ||
        p.papeis.contains('SECRETARIA');
    final gerir =
        podeGerirContas(widget.user) &&
        (!contaDeGestao ||
            (widget.user?.permissoes.tem(Capacidade.papeisGestaoAtribuir) ??
                false));
    // Na própria conta não há "Desativar" nem "Redefinir senha" (troca de
    // senha é pelo perfil).
    final propriaConta = p.temUsuario && p.usuarioId == widget.user?.id;

    final acoes = <Widget>[
      if (status == null && convidar)
        FilledButton(
          onPressed: _ocupado ? null : () => _convidar(reenvio: false),
          child: const Text('Convidar'),
        ),
      if (status == 'CONVIDADO' && convidar)
        OutlinedButton(
          onPressed: _ocupado ? null : () => _convidar(reenvio: true),
          child: const Text('Reenviar convite'),
        ),
      if (status == 'ATIVO' && gerir && !propriaConta)
        OutlinedButton(
          onPressed: _ocupado ? null : _redefinir,
          child: const Text('Redefinir senha'),
        ),
      if ((status == 'ATIVO' || status == 'CONVIDADO') &&
          gerir &&
          !propriaConta)
        OutlinedButton(
          onPressed: _ocupado ? null : _desativar,
          child: const Text('Desativar'),
        ),
      if (status == 'DESATIVADO' && gerir)
        OutlinedButton(
          onPressed: _ocupado ? null : _reativar,
          child: const Text('Reativar'),
        ),
      if (p.temUsuario && widget.onPapeis != null)
        OutlinedButton(
          onPressed: _ocupado ? null : widget.onPapeis,
          child: const Text('Papéis'),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Acesso ao app',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: acessoStatusLabel(status),
                  success: status == 'ATIVO',
                ),
              ],
            ),
            if (acoes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: acoes),
            ],
          ],
        ),
      ),
    );
  }
}
