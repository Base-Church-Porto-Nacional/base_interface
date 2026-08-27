import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/nav_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final igrejaCtx = context.watch<IgrejaContext>();
    final navItems = visibleNavItems(auth.user?.roles ?? []);
    final location = GoRouterState.of(context).uri.path;
    final section = _findSection(location);
    final canSwitch = igrejaCtx.canSwitch(auth.user);

    return Scaffold(
      appBar: AppBar(
        title: Text(section?.label ?? igrejaCtx.selected?.nome ?? 'Base Church'),
        actions: [
          if (canSwitch)
            SizedBox(
              width: 160,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: AppColors.black,
                    style: const TextStyle(color: AppColors.white, fontSize: 13),
                    iconEnabledColor: AppColors.white,
                    items: [
                      for (final i in igrejaCtx.igrejas)
                        DropdownMenuItem(
                          value: i.id,
                          child: Text(i.nome, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    value: igrejaCtx.igrejas.any((i) => i.id == igrejaCtx.selectedIgrejaId)
                        ? igrejaCtx.selectedIgrejaId
                        : null,
                    onChanged: (id) {
                      if (id != null) igrejaCtx.select(id);
                    },
                  ),
                ),
              ),
            ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.white,
              child: Text(
                _initials(auth.user?.nome ?? ''),
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onPressed: () => context.push('/perfil'),
          ),
          TextButton(
            onPressed: () => auth.logout(),
            child: const Text('Sair'),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      igrejaCtx.selected?.nome ?? auth.user?.igrejaNome ?? 'Base Church',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      igrejaCtx.selected == null
                          ? 'Sistema de gestão'
                          : igrejaTipoLabel(igrejaCtx.selected!.tipo),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final item in navItems)
                      ListTile(
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: _isActive(location, item.path)
                                ? AppColors.white
                                : Colors.white70,
                            fontWeight: _isActive(location, item.path)
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        selected: _isActive(location, item.path),
                        selectedTileColor: Colors.white12,
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.path);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }

  NavItem? _findSection(String path) {
    for (final item in mainNav) {
      if (path == item.path || path.startsWith('${item.path}/')) return item;
      for (final child in item.children) {
        if (path == child.path || path.startsWith('${child.path}/')) {
          return item;
        }
      }
    }
    return null;
  }

  bool _isActive(String path, String target) =>
      path == target || path.startsWith('$target/');

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
