import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/nav_config.dart';
import '../../theme/app_colors.dart';

class FilterMenu extends StatefulWidget {
  const FilterMenu({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<FilterMenu> {
  @override
  Widget build(BuildContext context) {
    final active = widget.value != 'TODOS';

    return PopupMenuButton<String>(
      tooltip: 'Filtros',
      onSelected: widget.onChanged,
      itemBuilder: (_) => [
        for (final (value, label) in pessoaFiltros)
          PopupMenuItem(value: value, child: Text(label)),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.black : AppColors.white,
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.filter_list,
          color: active ? AppColors.white : AppColors.black,
          size: 20,
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
      ),
      onChanged: onChanged,
    );
  }
}

class SectionTabs extends StatelessWidget {
  const SectionTabs({
    super.key,
    required this.tabs,
    required this.currentPath,
  });

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
              color: selected ? AppColors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.black : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
