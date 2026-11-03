import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/igreja_service.dart';
import '../../services/pessoa_service.dart';
import '../../widgets/common.dart';
import '../../widgets/form_dialogs.dart';
import '../../widgets/link_acesso_dialog.dart';

class IgrejasScreen extends StatefulWidget {
  const IgrejasScreen({super.key});

  @override
  State<IgrejasScreen> createState() => _IgrejasScreenState();
}

class _IgrejasScreenState extends State<IgrejasScreen> {
  List<Igreja> _items = [];
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
      final user = context.read<AuthProvider>().user;
      if (user == null) return;
      final items = await context.read<IgrejaService>().listVisiveis(user);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Abre o detalhe e, na volta, recarrega a lista (o pastor pode ter mudado).
  Future<void> _abrir(Igreja i) async {
    await context.push('/igrejas/${i.id}');
    if (mounted) _load();
  }

  Future<void> _novaFilial() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isMatriz) return;
    if (!user.permissoes.tem(Capacidade.filialCriar)) return;
    Igreja? matriz;
    for (final i in _items) {
      if (i.isMatriz) matriz = i;
    }
    if (matriz == null) return;
    // Toda a rede visível: o servidor transfere pessoas da matriz ou de outra filial.
    final pessoas = await context.read<PessoaService>().listarTodas();
    // O titular da matriz e o próprio usuário não podem ser transferidos.
    final excluir = {
      if (matriz.pastorPessoaId.isNotEmpty) matriz.pastorPessoaId,
      ?user.pessoaId,
    };
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => FilialFormDialog(pessoas: pessoas, excluirIds: excluir),
    );
    if (result == null || !mounted) return;
    try {
      final r = await context.read<IgrejaService>().criarFilial(
            matrizId: matriz.id,
            nome: result['nome'] as String,
            pastorPessoaId: result['pastorPessoaId'] as String?,
            pastorNome: result['pastorNome'] as String?,
            pastorEmail: result['pastorEmail'] as String?,
            pastorWhatsapp: result['pastorWhatsapp'] as String?,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await context.read<IgrejaContext>().reload(context.read<AuthProvider>().user);
      _load();
      final ajustadas = r.participacoesAjustadas;
      if (ajustadas > 0) {
        messenger.showSnackBar(SnackBar(
          content: Text(
            ajustadas == 1
                ? '1 participação futura do pastor na igreja anterior foi ajustada (escala, culto ou cronograma).'
                : '$ajustadas participações futuras do pastor na igreja anterior foram ajustadas (escalas, cultos e cronograma).',
          ),
        ));
      }
      final convite = r.convite;
      if (convite != null && mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => LinkAcessoDialog(
            link: convite.link,
            enviadoWhatsapp: convite.enviadoWhatsapp,
          ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Gestão Igreja',
          description: 'Matriz e filiais. Cada igreja tem um pastor.',
          actions: [
            if (context.watch<AuthProvider>().user case final u?
                when u.isMatriz && u.permissoes.tem(Capacidade.filialCriar))
              FilledButton(onPressed: _novaFilial, child: const Text('Nova filial')),
          ],
        ),
        if (_loading)
          const LoadingView()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          ..._items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MobileListTile(
                title: i.nome,
                subtitle: 'Pastor: ${i.pastorNome}',
                trailing: StatusBadge(
                  label: igrejaTipoLabel(i.tipo).toUpperCase(),
                  success: i.isMatriz,
                ),
                onTap: () => _abrir(i),
                actions: [
                  OutlinedButton(
                    onPressed: () => _abrir(i),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
