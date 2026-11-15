import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../services/aniversario_service.dart';
import '../../utils/format.dart';
import '../../utils/permissions.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class AniversariantesScreen extends StatefulWidget {
  const AniversariantesScreen({super.key});

  @override
  State<AniversariantesScreen> createState() => _AniversariantesScreenState();
}

class _AniversariantesScreenState extends State<AniversariantesScreen> {
  List<Aniversariante> _items = [];
  bool _loading = true;
  bool _enviando = false;
  bool _podeEnviar = false;
  String? _error;
  final DateTime _data = DateTime.now();

  @override
  void initState() {
    super.initState();
    _podeEnviar = podeEnviarAniversarios(context.read<AuthProvider>().user);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _igrejaId => context.read<IgrejaContext>().selectedIgrejaId ?? '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<AniversarioService>().listarAniversariantes(
        igrejaId: _igrejaId,
      );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Com Rabbit habilitado o POST só enfileira: o status real vem do histórico,
  /// então esperamos os PENDENTE saírem antes de dizer que deu certo.
  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      final service = context.read<AniversarioService>();
      final resumo = await service.enviarHoje(igrejaId: _igrejaId);
      if (resumo.temPendencia) {
        final concluded = await _aguardarProcessamento();
        if (!mounted) return;
        final texto = concluded
            ? 'Envios processados: ${resumo.resumo}'
            : 'Mensagens enfileiradas. Consulte o histórico para acompanhar.';
        showSnack(context, texto);
      } else {
        if (!mounted) return;
        showSnack(context, resumo.resumo);
      }
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<bool> _aguardarProcessamento() async {
    final service = context.read<AniversarioService>();
    for (var tentativa = 0; tentativa < 5; tentativa++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final envios = await service.listarEnvios(igrejaId: _igrejaId);
      if (!envios.any((e) => e.status == AniversarioEnvioStatus.pendente)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTabs(
          currentPath: '/aniversariantes',
          tabs: [
            ('/aniversariantes', 'Aniversariantes'),
            if (_podeEnviar) ('/aniversariantes/envios', 'Envios'),
          ],
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    return _corpo();
  }

  Widget _corpo() {
    final enviados = _items.where((a) => a.enviado).length;
    final pendentes = _items.length - enviados;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Aniversariantes do dia',
          description: 'Hoje, ${formatDate(isoDate(_data))} — $enviados já '
              'enviados e $pendentes pendentes.',
          actions: [
            if (_podeEnviar)
              FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: const Icon(Icons.send, size: 18),
                label: Text(_enviando ? 'Enviando…' : 'Enviar hoje'),
              ),
          ],
        ),
        if (_podeEnviar && pendentes > 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: StatusBadge(
              label: 'Reenviar o dia não duplica quem já recebeu a mensagem',
              success: false,
            ),
          ),
        if (_items.isEmpty)
          const Card(child: EmptyView(message: 'Nenhum aniversário para hoje.')),
        for (final a in _items) ...[
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  a.idade.toString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              title: Text(a.nome),
              subtitle: Text('${a.mensagem}\nNascimento: ${formatDate(a.dataNascimento)}'),
              isThreeLine: true,
              trailing: a.enviado
                  ? const StatusBadge(label: 'Enviado', success: true)
                  : const StatusBadge(label: 'Pendente'),
              onTap: () => context.push('/membros/pessoa/${a.pessoaId}'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
