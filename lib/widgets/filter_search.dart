import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/nav_config.dart';
import '../../theme/brand_colors.dart';

class FilterMenu extends StatelessWidget {
  const FilterMenu({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final active = value != 'TODOS';

    return PopupMenuButton<String>(
      tooltip: 'Filtros',
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final (value, label) in pessoaFiltros)
          PopupMenuItem(value: value, child: Text(label)),
      ],
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? brand.primary : brand.surface,
          border: Border.all(color: brand.borderStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.filter_list,
          color: active ? brand.onPrimary : brand.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 250),
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, size: 20),
      ),
      onChanged: _onChanged,
    );
  }
}

class SectionTabs extends StatelessWidget {
  const SectionTabs({super.key, required this.tabs, required this.currentPath});

  final List<(String path, String label)> tabs;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (path, label) in tabs)
            _TabChip(
              label: label,
              selected: currentPath == path,
              onTap: () => context.go(path),
            ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? context.brand.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected
                ? context.brand.textPrimary
                : context.brand.textMuted,
          ),
        ),
      ),
    );
  }
}
