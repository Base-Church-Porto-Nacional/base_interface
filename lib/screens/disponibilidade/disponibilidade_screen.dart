import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/disponibilidade_service.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_search.dart';

class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  State<DisponibilidadeScreen> createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> {
  List<IndisponibilidadeSemanal> _semanal = [
    for (final d in DiaSemana.values) IndisponibilidadeSemanal(dia: d),
  ];
  List<IndisponibilidadeData> _datas = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _pessoaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final pessoaId = context.read<AuthProvider>().user?.pessoaId;
    if (pessoaId == null) {
      setState(() {
        _loading = false;
        _error = 'Sua conta não está vinculada a uma pessoa.';
      });
      return;
    }
    _pessoaId = pessoaId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<DisponibilidadeService>().getByPessoa(pessoaId);
      IndisponibilidadeSemanal semanalDoDia(DiaSemana dia, List<IndisponibilidadeSemanal> list) {
        for (final s in list) {
          if (s.dia == dia) return s;
        }
        return IndisponibilidadeSemanal(dia: dia);
      }

      final merged = [
        for (final dia in DiaSemana.values) semanalDoDia(dia, data.semanal),
      ];
      if (mounted) {
        setState(() {
          _semanal = merged;
          _datas = List.of(data.datas)..sort((a, b) => a.data.compareTo(b.data));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSemanal() async {
    final pessoaId = _pessoaId;
    if (pessoaId == null) return;
    setState(() => _saving = true);
    try {
      await context.read<DisponibilidadeService>().saveSemanal(
            pessoaId: pessoaId,
            semanal: _semanal.where((s) => s.marcado).toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dias da semana atualizados.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addData() async {
    final pessoaId = _pessoaId;
    if (pessoaId == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 8, 26),
      firstDate: DateTime(2026),
      lastDate: DateTime(2029),
    );
    if (picked == null || !mounted) return;
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Não posso servir em ${formatDateShort(isoDate(picked))}'),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Adicionar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<DisponibilidadeService>().addData(
            pessoaId: pessoaId,
            data: isoDate(picked),
            motivo: motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim(),
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _removeData(IndisponibilidadeData item) async {
    final pessoaId = _pessoaId;
    if (pessoaId == null) return;
    await context.read<DisponibilidadeService>().removeData(pessoaId, item.id);
    _load();
  }

  void _toggle(int index, String periodo, bool value) {
    final current = _semanal[index];
    setState(() {
      _semanal[index] = current.copyWith(
        manha: periodo == 'manha' ? value : current.manha,
        tarde: periodo == 'tarde' ? value : current.tarde,
        noite: periodo == 'noite' ? value : current.noite,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTabs(
          currentPath: '/perfil/disponibilidade',
          tabs: [
            ('/meu-servico', 'Visão geral'),
            ('/perfil/disponibilidade', 'Disponibilidade'),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        PageHeader(
                          title: 'Disponibilidade',
                          description:
                              'Marque os dias da semana em que não pode servir e as datas do mês (ex.: 01/02, 02/11).',
                          actions: [
                            FilledButton(
                              onPressed: _saving ? null : _saveSemanal,
                              child: Text(_saving ? 'Salvando…' : 'Salvar semana'),
                            ),
                          ],
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                for (var i = 0; i < _semanal.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          child: Text(
                                            diaSemanaLabel(_semanal[i].dia),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontSize: 13),
                                          ),
                                        ),
                                        _chip(
                                          'Manhã',
                                          _semanal[i].manha,
                                          (v) => _toggle(i, 'manha', v),
                                        ),
                                        _chip(
                                          'Tarde',
                                          _semanal[i].tarde,
                                          (v) => _toggle(i, 'tarde', v),
                                        ),
                                        _chip(
                                          'Noite',
                                          _semanal[i].noite,
                                          (v) => _toggle(i, 'noite', v),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PageHeader(
                          title: 'Datas do mês',
                          actions: [
                            FilledButton(
                              onPressed: _addData,
                              child: const Text('Adicionar data'),
                            ),
                          ],
                        ),
                        if (_datas.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma data específica bloqueada.'),
                          )
                        else
                          ..._datas.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MobileListTile(
                                title: formatDateShort(d.data),
                                subtitle: d.motivo,
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _removeData(d),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onChanged,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
