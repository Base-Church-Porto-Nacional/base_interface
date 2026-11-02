import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/pessoa_service.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../utils/route_access.dart';
import '../../widgets/acesso_app_card.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_widgets.dart';
import '../../widgets/form_dialogs.dart';

class PessoaDetailScreen extends StatefulWidget {
  const PessoaDetailScreen({super.key, required this.pessoaId});

  final String pessoaId;

  @override
  State<PessoaDetailScreen> createState() => _PessoaDetailScreenState();
}

class _PessoaDetailScreenState extends State<PessoaDetailScreen> {
  Pessoa? _pessoa;
  List<PessoaHistorico> _historico = [];
  bool _loading = true;
  String? _error;
  int _tab = 0;

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
      final service = context.read<PessoaService>();
      final results = await Future.wait([
        service.getById(widget.pessoaId),
        service.listHistorico(widget.pessoaId),
      ]);
      if (mounted) {
        setState(() {
          _pessoa = results[0] as Pessoa;
          _historico = results[1] as List<PessoaHistorico>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Depois de qualquer ação de acesso: recarrega a pessoa sem trocar a tela
  /// por um spinner e, se a conta é a do próprio usuário, as permissões.
  Future<void> _aposAcesso() async {
    final auth = context.read<AuthProvider>();
    final usuarioId = _pessoa?.usuarioId;
    try {
      final p = await context.read<PessoaService>().getById(widget.pessoaId);
      if (mounted) setState(() => _pessoa = p);
    } catch (_) {}
    if (usuarioId != null && usuarioId == auth.user?.id) await auth.recarregarMe();
  }

  Future<void> _gerirPapeis() async {
    final p = _pessoa;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final usuarioId = p?.usuarioId;
    if (p == null || usuarioId == null || user == null) return;
    final podeGestao = user.permissoes.tem(Capacidade.papeisGestaoAtribuir);
    final podeCustom = user.permissoes.tem(Capacidade.papeisCustomGerir);
    if (!podeGestao && !podeCustom) return;
    final usuarioService = context.read<UsuarioService>();
    try {
      final customizados =
          podeCustom ? await usuarioService.listarPapeisCustomizados(p.igrejaId) : <String>[];
      if (!mounted) return;
      final novos = await showDialog<List<String>>(
        context: context,
        builder: (_) => PapeisDialog(
          pessoaNome: p.nome,
          atuais: p.papeis,
          customizados: customizados,
          podeGestao: podeGestao,
          podeCustom: podeCustom,
          onCriarPapel: podeCustom
              ? (nome, contagem) async {
                  await usuarioService.criarPapel(
                    nome: nome,
                    podeLancarContagem: contagem,
                    igrejaId: p.igrejaId,
                  );
                  return usuarioService.listarPapeisCustomizados(p.igrejaId);
                }
              : null,
        ),
      );
      if (novos == null || !mounted) return;
      await usuarioService.alterarPapeis(usuarioId, novos);
      // Mudou os papéis da própria conta: o servidor invalida o token e
      // recalcula as permissões; recarregarMe() reflete isso no app.
      if (usuarioId == user.id) await auth.recarregarMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Papéis atualizados.')),
      );
      _aposAcesso();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _editPessoa() async {
    final p = _pessoa;
    if (p == null) return;
    if (!canCadastrarPessoas(context.read<AuthProvider>().user)) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => PessoaFormDialog(
        title: 'Editar pessoa',
        initialNome: p.nome,
        initialTelefone: p.telefone,
        initialEmail: p.email,
        initialWhatsapp: p.whatsapp,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final updated = await context.read<PessoaService>().update(
            widget.pessoaId,
            nome: result['nome']!,
            telefone: result['telefone'],
            email: result['email'],
            whatsapp: result['whatsapp'],
          );
      if (mounted) {
        setState(() => _pessoa = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pessoa atualizada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _pessoa == null) {
      return ErrorView(message: _error ?? 'Pessoa não encontrada.', onRetry: _load);
    }

    final p = _pessoa!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHero(p),
        const SizedBox(height: 16),
        AcessoAppCard(
          pessoa: p,
          user: context.watch<AuthProvider>().user,
          onAlterado: _aposAcesso,
          onPapeis: _podeGerirPapeis(p) ? _gerirPapeis : null,
        ),
        const SizedBox(height: 20),
        SectionTabBar(
          tabs: const ['Perfil', 'Jornada', 'Histórico'],
          selectedIndex: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (_tab) {
            0 => _buildPerfil(p),
            1 => _buildJornada(p),
            _ => _buildHistorico(),
          },
        ),
      ],
    );
  }

  bool _podeGerirPapeis(Pessoa p) {
    final user = context.read<AuthProvider>().user;
    return p.temUsuario &&
        user != null &&
        (user.permissoes.tem(Capacidade.papeisGestaoAtribuir) ||
            user.permissoes.tem(Capacidade.papeisCustomGerir));
  }

  Widget _buildHero(Pessoa p) {
    final papeis = p.papeisExibiveis.map(papelLabel).join(' · ');
    final user = context.watch<AuthProvider>().user;
    final podeEditar = canCadastrarPessoas(user);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(name: p.nome, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.nome, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              if (papeis.isNotEmpty)
                Text(papeis, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusBadge(
                    label: pessoaStatusLabel(p.status),
                    success: p.status == PessoaStatus.ativo,
                  ),
                  if (p.ministerios.isNotEmpty)
                    for (final m in p.ministerios.take(2))
                      StatusBadge(label: m),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (podeEditar)
          Column(
            children: [
              if (podeEditar)
                FilledButton(
                  onPressed: _editPessoa,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Editar'),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPerfil(Pessoa p) {
    return DetailInfoCard(
      key: const ValueKey('perfil'),
      rows: [
        DetailInfoRow('Telefone', p.telefone.isNotEmpty ? p.telefone : '—'),
        DetailInfoRow('E-mail', p.email.isNotEmpty ? p.email : '—'),
        DetailInfoRow('WhatsApp', p.temWhatsapp ? p.whatsapp : '—'),
        DetailInfoRow(
          'Status',
          StatusBadge(
            label: pessoaStatusLabel(p.status),
            success: p.status == PessoaStatus.ativo,
          ),
        ),
        DetailInfoRow('Cadastro', formatDate(p.dataCadastro)),
        DetailInfoRow('Acesso ao app', acessoStatusLabel(p.acessoStatus)),
        if (p.ministerios.isNotEmpty)
          DetailInfoRow('Ministérios', p.ministerios.join(', ')),
      ],
    );
  }

  Widget _buildJornada(Pessoa p) {
    if (p.jornada.isEmpty) {
      return const EmptyStateCard(
        key: ValueKey('jornada-empty'),
        message: 'Nenhuma etapa registrada na jornada.',
        icon: Icons.route_outlined,
      );
    }

    return Card(
      key: const ValueKey('jornada'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          children: [
            for (var i = 0; i < p.jornada.length; i++)
              _JornadaStep(
                etapa: p.jornada[i],
                isLast: i == p.jornada.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorico() {
    if (_historico.isEmpty) {
      return const EmptyStateCard(
        key: ValueKey('historico-empty'),
        message: 'Nenhum registro no histórico.',
        icon: Icons.history,
      );
    }

    return Column(
      key: const ValueKey('historico'),
      children: [
        for (final h in _historico)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        formatDate(h.dataRegistro),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.descricao,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${h.autorNome}${h.autorCargo != null ? ' · ${h.autorCargo}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _JornadaStep extends StatelessWidget {
  const _JornadaStep({required this.etapa, required this.isLast});

  final JornadaEtapa etapa;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final concluido = etapa.status == JornadaEtapaStatus.concluido;
    final atual = etapa.status == JornadaEtapaStatus.atual;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: concluido
                        ? AppColors.black
                        : atual
                            ? AppColors.white
                            : AppColors.gray50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: concluido || atual ? AppColors.black : AppColors.borderStrong,
                      width: atual ? 2 : 1,
                    ),
                  ),
                  child: concluido
                      ? const Icon(Icons.check, size: 12, color: AppColors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etapa.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  if (etapa.data != null) ...[
                    const SizedBox(height: 2),
                    Text(formatDate(etapa.data!), style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (atual) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Etapa atual',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
