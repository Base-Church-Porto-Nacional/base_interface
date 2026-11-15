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

  static const double _compactWidth = 400;
  static const double _compactTextScale = 1.3;
  static const double _wideWidth = 900;
  static const double _selectorMinWidth = 88;
  static const double _selectorShare = 0.4;
  static const double _selectorWidth = 180;
  static const double _selectorWideWidth = 260;

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
    final compact =
        width < _compactWidth ||
        MediaQuery.textScalerOf(context).scale(1) > _compactTextScale;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                      section?.label ??
                          igrejaCtx.selected?.nome ??
                          'Base Church',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: brand.textPrimary),
                    ),
                  ),
                  if (canSwitch) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: (width * _selectorShare).clamp(
                        _selectorMinWidth,
                        width >= _wideWidth
                            ? _selectorWideWidth
                            : _selectorWidth,
                      ),
                      child: _IgrejaSelector(igrejaCtx: igrejaCtx),
                    ),
                  ],
                  if (compact)
                    _ProfileMenu(
                      avatar: _avatar(context, auth),
                      onLogout: auth.logout,
                    )
                  else ...[
                    IconButton(
                      tooltip: 'Perfil',
                      icon: _avatar(context, auth),
                      onPressed: () => context.push('/perfil'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: brand.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () => auth.logout(),
                      child: const Text('Sair'),
                    ),
                  ],
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
                          _NavTile(
                            label: item.label,
                            active: _isActive(location, item.path),
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
        ),
        body: child,
      ),
    );
  }

  Widget _avatar(BuildContext context, AuthProvider auth) {
    final brand = context.brand;
    return CircleAvatar(
      radius: 14,
      backgroundColor: brand.primary,
      child: Text(
        initials(auth.user?.nome ?? ''),
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: brand.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onInverse = context.brand.onInverse;
    final active = widget.active;
    final radius = BorderRadius.circular(8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: FocusRing(
        focused: _focused,
        borderRadius: radius,
        color: onInverse,
        child: Semantics(
          button: true,
          selected: active,
          child: Material(
            color: active
                ? onInverse.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onFocusChange: (v) => setState(() => _focused = v),
              hoverColor: onInverse.withValues(alpha: 0.06),
              focusColor: onInverse.withValues(alpha: 0.12),
              highlightColor: onInverse.withValues(alpha: 0.12),
              splashColor: onInverse.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: active
                        ? onInverse
                        : onInverse.withValues(alpha: 0.7),
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.avatar, required this.onLogout});

  final Widget avatar;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Perfil',
      icon: avatar,
      onSelected: (value) {
        if (value == 'sair') {
          onLogout();
        } else {
          context.push('/perfil');
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'perfil', child: Text('Perfil')),
        PopupMenuItem(value: 'sair', child: Text('Sair')),
      ],
    );
  }
}

class _IgrejaSelector extends StatelessWidget {
  const _IgrejaSelector({required this.igrejaCtx});

  final IgrejaContext igrejaCtx;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: brand.textPrimary, fontWeight: FontWeight.w500);
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: brand.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: brand.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }
}
