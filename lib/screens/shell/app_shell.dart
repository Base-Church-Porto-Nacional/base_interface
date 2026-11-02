import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/nav_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/igreja_context.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_typography.dart';
import '../../theme/brand_colors.dart';
import '../../utils/format.dart';
import '../../widgets/brand/brand.dart';

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

    final brand = context.brand;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: brand.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GlassSurface(
          radius: 0,
          level: Elevation.e1,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    color: brand.textPrimary,
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                BrandMark(size: 24, color: brand.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section?.label ?? igrejaCtx.selected?.nome ?? 'Base Church',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: brand.textPrimary),
                  ),
                ),
                if (canSwitch) ...[
                  const SizedBox(width: 8),
                  _IgrejaSelector(
                    igrejaCtx: igrejaCtx,
                    width: width < 520 ? 120 : 180,
                  ),
                ],
                IconButton(
                  tooltip: 'Perfil',
                  icon: CircleAvatar(
                    radius: 14,
                    backgroundColor: brand.primary,
                    child: Text(
                      initials(auth.user?.nome ?? ''),
                      style: TextStyle(
                        color: brand.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onPressed: () => context.push('/perfil'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: brand.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => auth.logout(),
                  child: const Text('Sair'),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: SpotlightBlock(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandSeal(size: 72, color: brand.onInverse),
                      const SizedBox(height: 20),
                      Text(
                        igrejaCtx.selected?.nome ??
                            auth.user?.igrejaNome ??
                            'Base Church',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: brand.onInverse),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (igrejaCtx.selected == null
                                ? 'Sistema de gestão'
                                : igrejaTipoLabel(igrejaCtx.selected!.tipo))
                            .toUpperCase(),
                        style: AppTypography.eyebrow.copyWith(
                          color: brand.onInverse.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: brand.onInverse.withValues(alpha: 0.12),
                  height: 1,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    children: [
                      for (final item in navItems)
                        _navTile(context, item.label, item.path, location),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AmbientBackground(child: child),
    );
  }

  Widget _navTile(
    BuildContext context,
    String label,
    String path,
    String location,
  ) {
    final onInverse = context.brand.onInverse;
    final active = _isActive(location, path);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? onInverse.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            context.go(path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: active ? onInverse : onInverse.withValues(alpha: 0.7),
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
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
}

class _IgrejaSelector extends StatelessWidget {
  const _IgrejaSelector({required this.igrejaCtx, required this.width});

  final IgrejaContext igrejaCtx;
  final double width;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: brand.textPrimary, fontWeight: FontWeight.w500);
    return SizedBox(
      width: width,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: brand.border),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              dropdownColor: brand.surfaceOverlay,
              borderRadius: BorderRadius.circular(12),
              style: style,
              iconEnabledColor: brand.textSecondary,
              items: [
                for (final i in igrejaCtx.igrejas)
                  DropdownMenuItem(
                    value: i.id,
                    child: Text(i.nome, overflow: TextOverflow.ellipsis),
                  ),
              ],
              value:
                  igrejaCtx.igrejas.any(
                    (i) => i.id == igrejaCtx.selectedIgrejaId,
                  )
                  ? igrejaCtx.selectedIgrejaId
                  : null,
              onChanged: (id) {
                if (id != null) igrejaCtx.select(id);
              },
            ),
          ),
        ),
      ),
    );
  }
}
