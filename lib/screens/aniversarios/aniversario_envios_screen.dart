import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/igreja_context.dart';
import '../../services/aniversario_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class AniversarioEnviosScreen extends StatefulWidget {
  const AniversarioEnviosScreen({super.key});

  @override
  State<AniversarioEnviosScreen> createState() => _AniversarioEnviosScreenState();
}

class _AniversarioEnviosScreenState extends State<AniversarioEnviosScreen> {
  List<AniversarioEnvio> _items = [];
  bool _loading = true;
  String? _error;
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  String get _igrejaId => context.read<IgrejaContext>().selectedIgrejaId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<AniversarioService>().listarEnvios(
        igrejaId: _igrejaId,
        de: isoDate(_periodo.start),
        ate: isoDate(_periodo.end),
      );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _escolherPeriodo() async {
    final escolha = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _periodo,
    );
    if (escolha == null) return;
    setState(() => _periodo = escolha);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTabs(
          currentPath: '/aniversariantes/envios',
          tabs: [
            ('/aniversariantes', 'Aniversariantes'),
            ('/aniversariantes/envios', 'Envios'),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _corpo(),
        ),
      ],
    );
  }

  Widget _corpo() {
    final pendentes =
        _items.where((e) => e.status == AniversarioEnvioStatus.pendente).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PageHeader(
          title: 'Envios de aniversário',
          description: 'Histórico retornado pelo servidor entre '
              '${formatDate(isoDate(_periodo.start))} e '
              '${formatDate(isoDate(_periodo.end))}.',
          actions: [
            OutlinedButton.icon(
              onPressed: _escolherPeriodo,
              icon: const Icon(Icons.date_range, size: 18),
              label: const Text('Período'),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
            ),
          ],
        ),
        if (pendentes > 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: StatusBadge(
              label: 'Envios ainda processando pelo servidor',
              success: false,
            ),
          ),
        if (_items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Nenhum envio no período.')),
            ),
          ),
        for (final e in _items) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Aniversário em ${formatDate(e.dataAniversario)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                        ),
                      ),
                      StatusBadge(
                        label: aniversarioEnvioStatusLabel(e.status),
                        success: e.status == AniversarioEnvioStatus.enviado,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(e.mensagem, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Processado em ${formatDateTime(e.dataProcessamento)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (e.erro != null && e.erro!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      e.erro!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _copiar(e),
                      child: const Text('Copiar mensagem'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _copiar(AniversarioEnvio envio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(envio.mensagem)),
    );
  }
}
