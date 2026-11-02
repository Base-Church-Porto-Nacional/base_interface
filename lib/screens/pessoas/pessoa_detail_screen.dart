import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/pessoa_service.dart';
import '../../services/usuario_service.dart';
import '../../theme/brand_colors.dart';
import '../../utils/format.dart';
import '../../utils/route_access.dart';
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
  List<JornadaEtapa> _jornada = [];
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
        service.jornada(widget.pessoaId).catchError((_) => <JornadaEtapa>[]),
      ]);
      if (mounted) {
        setState(() {
          _pessoa = results[0] as Pessoa;
          _historico = results[1] as List<PessoaHistorico>;
          _jornada = results[2] as List<JornadaEtapa>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _criarUsuario() async {
    final p = _pessoa;
    if (p == null || p.temUsuario) return;
    if (!canCreateUsuario(context.read<AuthProvider>().user)) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UsuarioFormDialog(
        pessoaNome: p.nome,
        email: p.email,
        voluntario: p.tipos.contains(PessoaTipo.voluntario),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<UsuarioService>().createFromPessoa(
            pessoaId: p.id,
            username: result['username'] as String,
            email: result['email'] as String,
            senha: result['senha'] as String,
            papeis: (result['papeis'] as List<Role>),
            igrejaId: p.igrejaId,
          );
      if (mounted) {
        showSnack(context, 'Usuário criado. A pessoa já pode acompanhar escalas e eventos.');
        _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, e);
    }
  }

  Future<void> _editPessoa() async {
    final p = _pessoa;
    if (p == null) return;
    if (!canMutatePessoas(context.read<AuthProvider>().user)) return;

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
        showSnack(context, 'Pessoa atualizada.');
      }
    } catch (e) {
      if (mounted) showSnack(context, e);
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
            1 => _buildJornada(),
            _ => _buildHistorico(),
          },
        ),
      ],
    );
  }

  Widget _buildHero(Pessoa p) {
    final papeis = p.papeis.map(roleLabel).join(' · ');
    final user = context.watch<AuthProvider>().user;
    final podeEditar = canMutatePessoas(user);
    final podeCriarConta = canCreateUsuario(user) && !p.temUsuario;

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
        if (podeEditar || podeCriarConta)
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
              if (podeCriarConta) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _criarUsuario,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Criar usuário'),
                ),
              ],
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
        DetailInfoRow('Usuário', p.temUsuario ? 'Sim' : 'Não'),
        if (p.ministerios.isNotEmpty)
          DetailInfoRow('Ministérios', p.ministerios.join(', ')),
      ],
    );
  }

  Widget _buildJornada() {
    if (_jornada.isEmpty) {
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
            for (var i = 0; i < _jornada.length; i++)
              _JornadaStep(
                etapa: _jornada[i],
                isLast: i == _jornada.length - 1,
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
                              color: context.brand.textSecondary,
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
                        ? context.brand.primary
                        : atual
                            ? context.brand.surface
                            : context.brand.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: concluido || atual ? context.brand.primary : context.brand.borderStrong,
                      width: atual ? 2 : 1,
                    ),
                  ),
                  child: concluido
                      ? Icon(Icons.check, size: 12, color: context.brand.onPrimary)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: context.brand.border,
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
                            color: context.brand.textSecondary,
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
