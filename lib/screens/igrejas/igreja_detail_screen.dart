import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/igreja_service.dart';
import '../../services/pessoa_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';
import '../../widgets/link_acesso_dialog.dart';

class IgrejaDetailScreen extends StatefulWidget {
  const IgrejaDetailScreen({super.key, required this.igrejaId});

  final String igrejaId;

  @override
  State<IgrejaDetailScreen> createState() => _IgrejaDetailScreenState();
}

class _IgrejaDetailScreenState extends State<IgrejaDetailScreen> {
  Igreja? _igreja;
  bool _loading = true;
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
      final igreja = await context.read<IgrejaService>().getById(widget.igrejaId);
      if (mounted) setState(() => _igreja = igreja);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _podeTrocarPastor(Igreja i) {
    final u = context.read<AuthProvider>().user;
    if (u == null) return false;
    if (u.isMatriz && u.permissoes.tem(Capacidade.filialCriar)) return true;
    return u.pessoaId != null && u.pessoaId == i.pastorPessoaId;
  }

  Future<void> _trocarPastor(Igreja i) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pessoas = await context.read<PessoaService>().list(size: 100, igrejaId: i.id);
      if (!mounted) return;
      final id = await showDialog<String>(
        context: context,
        builder: (_) => TrocarPastorDialog(pessoas: pessoas.content, atualId: i.pastorPessoaId),
      );
      if (id == null || !mounted) return;
      final r = await context.read<IgrejaService>().trocarPastor(i.id, id);
      if (!mounted) return;
      setState(() => _igreja = r.igreja);
      final convite = r.convite;
      if (convite != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => LinkAcessoDialog(
            link: convite.link,
            enviadoWhatsapp: convite.enviadoWhatsapp,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null || _igreja == null) {
      return ErrorView(message: _error ?? 'Igreja não encontrada.', onRetry: _load);
    }
    final i = _igreja!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: i.nome,
          description: i.isMatriz
              ? 'Igreja matriz — acesso a toda a rede.'
              : 'Igreja filial — escopo restrito a esta igreja.',
          actions: [
            if (_podeTrocarPastor(i))
              FilledButton(
                onPressed: () => _trocarPastor(i),
                child: const Text('Trocar pastor'),
              ),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Voltar')),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Tipo', igrejaTipoLabel(i.tipo)),
                _row('Pastor', i.pastorNome),
                _row('Status', i.ativo ? 'Ativa' : 'Inativa'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
