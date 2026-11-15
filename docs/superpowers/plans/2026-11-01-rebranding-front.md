# Rebranding do front — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplicar o guia `docs/BRAND.md` ao app: tokens claro/escuro, logos, vidro, luz/sombra, novo login/splash/shell/dashboard e migração das telas.

**Architecture:** Tokens semânticos num `ThemeExtension` (`BrandColors`) lidos via `context.brand`; `AppTheme.light`/`dark` com `ThemeMode.system`. Linguagem de marca concentrada em widgets de `lib/widgets/brand/`. Telas migram de `AppColors` estático para `context.brand`, e `AppColors` é removido no fim.

**Tech Stack:** Flutter 3.47.1 / Dart ^3.13, `flutter_svg` (novo), `google_fonts` (DM Sans), Archivo variável embutida, `BackdropFilter` nativo para o vidro.

**Spec:** `docs/BRAND.md`

## Global Constraints

- `flutter analyze` sem erros/avisos novos; os 15 `info` antigos tolerados, nenhum novo.
- Sem comentários no código (CLAUDE.md).
- Texto de UI em português; identificadores seguem o padrão do repo.
- Telas usam **só** tokens semânticos (`context.brand.*`, `Theme.of(context)`); nenhum `Color(0x…)` / `Colors.*` fora de `lib/theme/` e `lib/widgets/brand/`, exceto `Colors.transparent`.
- Archivo só nos estilos `hero`, `pageTitle`, `stat`, `eyebrow`; nunca abaixo de 12px.
- Alvos de toque ≥ 48px; inputs e botão primário com 48 de altura.
- Todo movimento desliga com `MediaQuery.disableAnimationsOf(context)`.
- Vidro vira sólido (`surfaceOverlay` + mesma borda/sombra) quando `MediaQuery.highContrastOf(context)`.
- Novos serviços/providers: nenhum. `app.dart` só ganha `darkTheme`, `themeMode` e a splash.
- Branch: `feat/rebranding` a partir de `main`; um commit por task, mensagem em português no padrão `tipo(escopo): …`.

## Review Focus

1. **Nomes longos** (igreja "Base Church Porto Nacional — Setor Aeroporto", usuário com 5 nomes) no drawer e na saudação → reticências, nunca overflow. Teste na Task 5 e Task 6.
2. **Escala de fonte 200%** no login em 390px → sem overflow, rola. Teste na Task 4.
3. **Modo escuro** com dropdown de igreja, snackbar e badges de status → texto legível (contraste ≥ 4.5). Teste de contraste na Task 2 cobre os pares de token.
4. **Reduzir movimento** → anel do selo e luz ambiente param. Teste na Task 3.
5. **Usuário sem nome** (`nome` vazio) → saudação "BOA NOITE" sem vírgula pendurada. Teste na Task 6.

---

### Task 0: Branch

- [ ] `git stash push deploy/stack.yml -m "wip stack"` (mudança alheia ao rebranding), `git switch main && git pull && git switch -c feat/rebranding`. `docs/BRAND.md`, `docs/superpowers/` e `assets/brand/` são untracked e acompanham.
- [ ] Commit: `docs: guia de estilo e plano do rebranding` com `docs/`.

### Task 1: Assets de marca e fontes

**Files:**
- Create: `assets/brand/selo.svg`, `assets/brand/selo_anel.svg`, `assets/brand/b.svg`, `assets/brand/grain.png`, `assets/fonts/Archivo-Variable.ttf`, `assets/fonts/OFL.txt`
- Já presentes: `assets/brand/logo_preta.png`, `logo_branca.png`, `logo_base_church.pdf`
- Modify: `pubspec.yaml`
- Test: `test/theme/brand_assets_test.dart`

**Interfaces:**
- Produces: caminhos `BrandAssets.selo`, `BrandAssets.anel`, `BrandAssets.b`, `BrandAssets.grain` (constantes `String` em `lib/theme/brand_assets.dart`); família de fonte `'Archivo'`.

- [ ] **Step 1: Teste que falha** — `brand assets carregam`: para cada caminho de `BrandAssets`, `await rootBundle.load(path)` tem `lengthInBytes > 0`; para os 3 SVGs, o texto contém exatamente um valor de `fill` distinto e nenhum `<image`.
- [ ] **Step 2:** `flutter test test/theme/brand_assets_test.dart` → FAIL (arquivo `brand_assets.dart` inexistente).
- [ ] **Step 3: Gerar SVGs.** `pdftocairo -svg -f 2 -l 2 assets/brand/logo_base_church.pdf` (página 2 = preto sobre branco). Remover o retângulo de fundo branco, se houver. Script Python (no scratchpad, `python3 -I`) que quebra o `d` dos `<path>` em subpaths (`M…Z`) e classifica por bbox: subpath cujo centro está a menos de 30% do lado da arte em relação ao centro → "B"; o resto → anel. Gravar `selo.svg` (todos), `selo_anel.svg`, `b.svg` (viewBox recortado no bbox do B + 4% de margem). `fill="#000000"` único. Conferir visualmente renderizando com `qlmanage -t -s 512` ou abrindo no Playwright.
- [ ] **Step 4: Grão.** Script Python sem dependências (`zlib` + `struct`) gera `grain.png` 128×128 RGBA, ruído branco com alfa aleatório 0–255 (opacidade final de 3% é aplicada no widget).
- [ ] **Step 5: Fonte.** Baixar `https://github.com/google/fonts/raw/main/ofl/archivo/Archivo%5Bwdth,wght%5D.ttf` → `assets/fonts/Archivo-Variable.ttf` e `OFL.txt` da mesma pasta.
- [ ] **Step 6: pubspec.** `flutter pub add flutter_svg`. Em `flutter:` → `assets: [assets/brand/]` e `fonts: - family: Archivo / fonts: - asset: assets/fonts/Archivo-Variable.ttf`.
- [ ] **Step 7:** criar `lib/theme/brand_assets.dart` com `abstract final class BrandAssets` e as 4 constantes.
- [ ] **Step 8:** teste → PASS; `flutter analyze` limpo.
- [ ] **Step 9: Verificar eixo `wdth` no web** — `Text('BEM-VINDO', style: TextStyle(fontFamily: 'Archivo', fontVariations: [FontVariation('wdth',125), FontVariation('wght',900)]))` num `flutter run -d chrome` temporário (não commitar); screenshot no Playwright comparando com `wdth 100`. Se não alargar, trocar a família por `Archivo Black` via `google_fonts` em `AppTypography` (Task 2) e anotar em `docs/BRAND.md` §5.
- [ ] **Step 10: Commit** `feat(brand): logos, textura e fonte Archivo`.

### Task 2: Tokens, tipografia, elevação e temas claro/escuro

**Files:**
- Create: `lib/theme/app_tokens.dart`, `lib/theme/brand_colors.dart`, `lib/theme/app_elevation.dart`, `lib/theme/app_typography.dart`
- Modify: `lib/theme/app_theme.dart`, `lib/app.dart`
- Test: `test/theme/brand_colors_test.dart`, `test/theme/app_theme_test.dart`, `test/helpers/contrast.dart`

**Interfaces:**
- Produces:
  - `abstract final class AppTokens` — primitivos de `BRAND.md` §4.2 como `static const Color` (`black, n950, n900, n850, n800, n750, n700, n500, n450, n400, n300, n200, n100, n50, white`).
  - `class BrandColors extends ThemeExtension<BrandColors>` com campos `Color` exatamente: `background, surface, surfaceRaised, surfaceOverlay, inverse, onInverse, textPrimary, textSecondary, textMuted, border, borderStrong, primary, onPrimary, focus, success, successBg, warning, warningBg, danger, dangerBg`; `static const light`, `static const dark` com os valores de §4.1; `copyWith`, `lerp`.
  - `extension BrandContext on BuildContext { BrandColors get brand; bool get isDark; }`
  - `enum Elevation { e0, e1, e2, e3 }`; `abstract final class AppElevation { static List<BoxShadow> shadows(Elevation e, Brightness b); static double highlightOpacity(Elevation e, Brightness b); }` — valores de §6.1 (claro: sombras pretas com as opacidades da tabela; escuro: `e0` [], `e1` [], `e2` preta 50% blur 24 y 8, `e3` preta 60% blur 48 y 24; highlight escuro e1 .06 / e2 .07 / e3 .08, claro 0).
  - `abstract final class AppTypography { static TextStyle hero; pageTitle; stat; eyebrow; }` — getters estáticos com valores de §5 (família `Archivo`, `fontVariations` wdth 125 + wght; `stat` com `FontFeature.tabularFigures()`), sem cor.
  - `AppTheme.light` / `AppTheme.dark` → `ThemeData` com `extensions: [BrandColors.light|dark]`, DM Sans para `textTheme` (tamanhos de §5), raios de §7 (cards/botões/inputs 8, diálogos 16), inputs `filled` com `surface` e altura 48, `FilledButton` `primary`/`onPrimary` 48 de altura, `cardTheme` com cor `surface` e `elevation: 0` (sombra vem do `BrandCard`), `scaffoldBackgroundColor: background`, `drawerTheme` `inverse`, `snackBarTheme` invertido, `focusColor`.
- Consumes: família `'Archivo'` (Task 1).

- [ ] **Step 1: Testes que falham.**
  - `test/helpers/contrast.dart`: `double contrastRatio(Color a, Color b)` (WCAG 2.x, luminância relativa).
  - `brand_colors_test.dart`: para `BrandColors.light` e `.dark`, `textPrimary`, `textSecondary`, `textMuted` têm contraste ≥ 4.5 contra `background`, `surface`, `surfaceRaised` e `surfaceOverlay`; `onInverse` vs `inverse` ≥ 4.5; `onPrimary` vs `primary` ≥ 4.5; `success`/`warning`/`danger` vs seus `*Bg` ≥ 4.5; `lerp(light, dark, 0)` == light.
  - `app_theme_test.dart`: `AppTheme.light.extension<BrandColors>()` == `BrandColors.light`; `AppTheme.dark.brightness == Brightness.dark`; `AppTheme.dark.colorScheme.primary == Color(0xFFFFFFFF)`; `AppTheme.light.colorScheme.primary == Color(0xFF000000)`; `AppTypography.hero.fontFamily == 'Archivo'` e `fontSize == 36`; `AppTypography.eyebrow.letterSpacing == 1.2`.
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3:** implementar os arquivos acima. Se algum par de contraste falhar com os valores do guia, ajustar o **valor** (mais escuro/claro) e refletir em `BRAND.md` §4.1.
- [ ] **Step 4:** `lib/app.dart`: os dois `MaterialApp` recebem `theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.system`.
- [ ] **Step 5:** `AppColors` continua existindo nesta task (as telas ainda dependem dele); `app_theme.dart` deixa de importá-lo.
- [ ] **Step 6:** `flutter test` (tudo) e `flutter analyze` → PASS/limpo.
- [ ] **Step 7: Commit** `feat(theme): tokens claro/escuro, tipografia e elevação`.

### Task 3: Componentes de marca

**Files:**
- Create em `lib/widgets/brand/`: `brand_seal.dart`, `brand_mark.dart`, `glass_surface.dart`, `ambient_background.dart`, `spotlight_block.dart`, `brand_card.dart`, `stat_tile.dart`, `info_pill.dart`, `brand.dart` (barrel export)
- Modify: `lib/widgets/common.dart` (`PageHeader`)
- Test: `test/widgets/brand_test.dart`, `test/helpers/pump.dart`

**Interfaces:**
- Consumes: `BrandAssets`, `BrandColors`/`context.brand`, `AppElevation`, `AppTypography`.
- Produces (assinaturas exatas):
  - `BrandSeal({double size = 120, bool spinning = false, Color? color})` — `Stack` de `selo_anel.svg` (gira 1 volta/60s linear quando `spinning` e animações habilitadas) + `b.svg`; cor padrão `textPrimary`; `Semantics(label: 'Base Church')`.
  - `BrandMark({double size = 24, Color? color})`.
  - `GlassSurface({required Widget child, double radius = 16, Elevation level = Elevation.e2, EdgeInsetsGeometry padding = EdgeInsets.zero})` — receita §6.4: `ClipRRect` → `BackdropFilter(ImageFilter.blur(24,24))` → `DecoratedBox` (tinta + borda gradiente + brilho interno), sombra por fora do clip; `highContrast` → sem `BackdropFilter`, fundo `surfaceOverlay`.
  - `AmbientBackground({required Widget child, bool animated = false})` — §6.3; `animated` deriva 20s, parado com `disableAnimations`.
  - `SpotlightBlock({required Widget child, BorderRadius? borderRadius})` — §6.2, cor `inverse`, grão `BrandAssets.grain` repetido a 3%; filhos herdam `onInverse` via `DefaultTextStyle`/`IconTheme`.
  - `BrandCard({required Widget child, VoidCallback? onTap, EdgeInsetsGeometry padding = const EdgeInsets.all(16)})` — `surface`, raio 8, `e1`; com `onTap` em hover (web/desktop) sobe 2px e vai para `e2` em 150ms; pressionado desce 1px.
  - `StatTile({required String label, required String value, IconData? icon})` — `BrandCard` com `label` em `bodySmall` e `value` em `AppTypography.stat`.
  - `InfoPill({required String text, IconData? icon})` — `GlassSurface(radius: 999, level: Elevation.e1)`, padding 12×6, `label`.
  - `PageHeader` ganha `String? eyebrow`; `title` passa a usar `AppTypography.pageTitle` em caixa-alta, `maxLines: 2`, `overflow: ellipsis`. Assinatura atual preservada (31 usos).
- `test/helpers/pump.dart`: `Future<void> pumpBrand(WidgetTester t, Widget w, {Brightness brightness = Brightness.light, bool disableAnimations = false, bool highContrast = false, Size size = const Size(390, 844), double textScale = 1})` envolvendo em `MaterialApp` com o tema correspondente e `MediaQuery`.

- [ ] **Step 1: Testes que falham** (`brand_test.dart`):
  - `GlassSurface usa BackdropFilter` → `find.byType(BackdropFilter)` findsOneWidget.
  - `GlassSurface sem vidro em alto contraste` → `highContrast: true` → findsNothing de `BackdropFilter`.
  - `BrandSeal gira só com animação habilitada` → `spinning: true`: com animações há `RotationTransition` cuja `turns.value` muda após `pump(Duration(seconds: 15))` (~0.25); com `disableAnimations: true`, `turns.value` == 0 após o mesmo pump.
  - `AmbientBackground parado com reduzir movimento` → `animated: true, disableAnimations: true` → `t.hasRunningAnimations` false.
  - `BrandSeal usa textPrimary no escuro` → no tema escuro o `SvgPicture` do `b.svg` tem `colorFilter` com `BrandColors.dark.textPrimary`.
  - `PageHeader mostra eyebrow e título em caixa-alta` → `PageHeader(eyebrow: 'Escalas · Novembro', title: 'Escalas')` mostra `'ESCALAS · NOVEMBRO'` e `'ESCALAS'`.
  - `StatTile` mostra `label` e `value`.
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** `flutter test` → PASS; `flutter analyze` limpo.
- [ ] **Step 5: Commit** `feat(brand): selo, vidro, luz ambiente e componentes de marca`.

### Task 4: Login e splash

**Files:**
- Modify: `lib/screens/login/login_screen.dart`, `lib/app.dart`
- Create: `lib/screens/splash/splash_screen.dart`
- Test: `test/screens/login_screen_test.dart`

**Interfaces:**
- Consumes: `BrandSeal`, `GlassSurface`, `SpotlightBlock`, `AmbientBackground`, `AppTypography`.
- Produces: `SplashScreen()` (sem parâmetros).

Layout exato em `BRAND.md` §9.1–9.2. Breakpoint 900px. Largo: `Row` com `SpotlightBlock` (selo 240, `spinning`, `AmbientBackground(animated: true)` dentro, eyebrow "2026 — A PARTIR DE JESUS" no rodapé do painel) e lado direito com `AmbientBackground` + card `GlassSurface(level: e3)` máx. 400. Estreito: `SpotlightBlock` com 40% da altura (selo 120) e o card sobrepondo 48px via `Stack`/`Transform.translate`, tudo dentro de `SingleChildScrollView`. Lógica atual (controllers, `_submit`, snackbar no `initState`, olho da senha, `onSubmitted`, loading) inalterada. Campos ganham `autofillHints` (`username`, `password`).

- [ ] **Step 1: Testes que falham** — montar com `ChangeNotifierProvider<AuthProvider>` (via `AuthService(ApiClient(prefs), prefs)` com `SharedPreferences.setMockInitialValues({})`):
  - `mostra selo e BEM-VINDO` (390×844) → `find.byType(BrandSeal)` e `find.text('BEM-VINDO')`.
  - `largo usa selo 240 girando` (1280×800) → `BrandSeal` com `size == 240` e `spinning == true`.
  - `sem overflow com fonte 200%` (390×844, `textScale: 2`) → `tester.takeException()` é null.
  - `Enter na senha chama login` → digitar usuário/senha, `testTextInput.receiveAction(TextInputAction.done)`, `pump` → `AuthProvider.isLoading` passou a true (ou request fake disparado via `fake_api.dart`).
- [ ] **Step 2:** rodar → FAIL.
- [ ] **Step 3:** implementar login; `SplashScreen` = `SpotlightBlock` tela cheia + `BrandSeal(size: 120, spinning: true, color: onInverse)` + `LinearProgressIndicator` de 2px, 160 de largura, abaixo; em `app.dart` o `home` de carregamento vira `const SplashScreen()`.
- [ ] **Step 4:** `flutter test` → PASS; `flutter analyze` limpo.
- [ ] **Step 5: Screenshots** — `flutter build web --dart-define=API_URL=http://localhost:8080/api`, servir `build/web` (`python3 -m http.server 8090 -d build/web`), Playwright em `/login` nos 4 cenários (claro/escuro via `browser_emulate_media colorScheme` × 390/1280). Salvar em `.playwright-mcp/` (não versionar) e revisar visualmente.
- [ ] **Step 6: Commit** `feat(login): login e splash com selo, vidro e luz`.

### Task 5: Shell (app bar e drawer)

**Files:**
- Modify: `lib/screens/shell/app_shell.dart`
- Test: `test/screens/app_shell_test.dart`

**Interfaces:**
- Consumes: `GlassSurface`, `SpotlightBlock`, `BrandSeal`, `BrandMark`, `AmbientBackground`, `context.brand`.

Spec `BRAND.md` §9.3 (versão revisada: conteúdo não passa sob a barra). App bar: `PreferredSize` com `GlassSurface(radius: 0, level: e1)`, `BrandMark(24)` + título `titleLarge` (ellipsis), seletor de igreja (quando `canSwitch`) como `DropdownButton` em pílula de vidro usando tokens (sem cores fixas), avatar com iniciais (`primary`/`onPrimary`), "Sair". Corpo: `AmbientBackground(child: child)`. Drawer: `SpotlightBlock` com `BrandSeal(72, color: onInverse)`, nome da igreja (`titleMedium`, `maxLines: 2`, ellipsis), linha `eyebrow` com o tipo da igreja; item ativo = pílula branca 8% com ícone preenchido — se `NavItem` não tiver ícone, só texto em peso 600. Lógica de navegação inalterada.

- [ ] **Step 1: Testes que falham** — montar `AppShell` dentro de um `GoRouter` mínimo com fixtures de `test/helpers/fixtures.dart`:
  - `drawer mostra selo e igreja` → abrir drawer, `find.byType(BrandSeal)` e o nome da igreja.
  - `nome de igreja longo não estoura` → igreja com nome de 80 caracteres, 390px → `takeException()` null.
  - `tema escuro sem exceção` → mesma montagem com `Brightness.dark`.
- [ ] **Step 2:** FAIL → **Step 3:** implementar → **Step 4:** PASS + analyze limpo.
- [ ] **Step 5: Commit** `feat(shell): app bar de vidro e drawer com holofote`.

### Task 6: Dashboard

**Files:**
- Modify: `lib/screens/dashboard/dashboard_screen.dart`, `lib/utils/format.dart`
- Test: `test/utils/format_test.dart`, `test/screens/dashboard_screen_test.dart`

**Interfaces:**
- Produces: `String saudacao(DateTime agora, String nome)` em `format.dart` → `"BOM DIA"` (5–11h), `"BOA TARDE"` (12–17h), `"BOA NOITE"` (resto); com nome não vazio acrescenta `", <PRIMEIRO NOME>"` em caixa-alta.
- Consumes: `StatTile`, `BrandCard`, `PageHeader(eyebrow:)`, `AppTypography.hero`.

Layout §9.4: saudação `hero` (ellipsis, `maxLines: 2`), eyebrow com nome da igreja selecionada (`IgrejaContext.selected?.nome`), grade de `StatTile` com 2 colunas < 600px e 4 ≥ 600px (`LayoutBuilder` + `GridView`/`Wrap` com largura calculada), cards "Jornada" e "Próximas escalas" em `BrandCard`. `ExportMenu` permanece nas ações. Tela de boas-vindas (`_semAcesso`) usa a mesma saudação.

- [ ] **Step 1: Testes que falham** em `format_test.dart`: `saudacao(DateTime(2026,1,1,8), 'Gustavo Veiga') == 'BOM DIA, GUSTAVO'`; `…14h…== 'BOA TARDE, GUSTAVO'`; `…23h… == 'BOA NOITE, GUSTAVO'`; `…3h, '' == 'BOA NOITE'`; `…12h, '  ' == 'BOA TARDE'`. Em `dashboard_screen_test.dart` (com `DashboardService` sobre `fake_api.dart` devolvendo stats): 4 `StatTile` aparecem; em 1280px ficam na mesma linha (mesmo `dy`).
- [ ] **Step 2:** FAIL → **Step 3:** implementar → **Step 4:** PASS + analyze.
- [ ] **Step 5: Commit** `feat(dashboard): saudação e indicadores com a linguagem da marca`.

### Task 7: Migração dos widgets compartilhados e estados

**Files:**
- Modify: `lib/widgets/common.dart`, `detail_widgets.dart`, `filter_search.dart`, `form_dialogs.dart`, `export_menu.dart`, `placeholder_screen.dart`
- Test: `test/widgets/common_test.dart`

**Interfaces:**
- Produces: `EmptyView({required String message, Widget? action})` (`BrandMark(48, color: textMuted)` + texto + ação); `LoadingView` passa a mostrar skeleton (3 blocos `surfaceRaised` raio 8, alturas 72, shimmer 1.2s parado com `disableAnimations`) mantendo o construtor `const LoadingView()`; `ErrorView` ganha ícone `danger`. `StatusBadge` mantém assinatura e passa a pílula (raio 999) com tokens. `MobileListTile` passa a usar `BrandCard(onTap:)`.

Mapa de substituição (vale para Tasks 7 e 8), sempre por intenção do uso:

| Antes | Depois |
|---|---|
| `AppColors.black` como texto/ícone | `brand.textPrimary` |
| `AppColors.black` como fundo de botão/seleção | `brand.primary` (texto `onPrimary`) |
| `AppColors.black` como fundo de bloco de marca | `brand.inverse` |
| `AppColors.white` como fundo | `brand.surface` |
| `AppColors.white` sobre preto | `brand.onPrimary` ou `onInverse` conforme o fundo |
| `AppColors.bg` / `gray50` | `brand.background` / `surfaceRaised` |
| `AppColors.surface/border/borderStrong/textSecondary/textMuted` | mesmo nome em `brand` |
| `AppColors.success/successBg/warning/danger/dangerBg` | mesmo nome em `brand` |
| `Colors.white70` / `white12` sobre `inverse` | `onInverse` com `.withValues(alpha: .7)` / `.12` |
| `Colors.green/amber/grey` | `brand.success` / `warning` / `textMuted` |
| `TextStyle(...)` inline com tamanho/peso | estilo do `textTheme` mais próximo + `copyWith(color:)` |

- [ ] **Step 1: Testes que falham**: `EmptyView` mostra `BrandMark` e mensagem; `StatusBadge(success: true)` no escuro usa `BrandColors.dark.success` no texto; `LoadingView` com `disableAnimations` → `hasRunningAnimations` false.
- [ ] **Step 2:** FAIL → **Step 3:** migrar arquivos pelo mapa → **Step 4:** PASS + analyze.
- [ ] **Step 5:** `grep -rn "AppColors\|Colors\.\(white\|black\|grey\|green\|amber\)" lib/widgets` → vazio.
- [ ] **Step 6: Commit** `refactor(widgets): tokens de marca e estados vazio/carregando`.

### Task 8: Migração das telas e remoção de `AppColors`

**Files:**
- Modify: todos os `.dart` em `lib/screens/` que importam `theme/app_colors.dart` (hoje: pessoas, escalas, culto, voluntariado, pequenos_grupos, meu_servico, configuracoes, login, shell)
- Delete: `lib/theme/app_colors.dart`
- Test: `test/theme/no_hardcoded_colors_test.dart`

- [ ] **Step 1: Teste que falha** — `no_hardcoded_colors_test.dart` lê todos os `.dart` de `lib/` fora de `lib/theme/` e `lib/widgets/brand/` e afirma que nenhum contém `AppColors`, `Color(0x` ou `Colors.` exceto `Colors.transparent`.
- [ ] **Step 2:** FAIL (lista os arquivos).
- [ ] **Step 3:** migrar um domínio por vez pelo mapa da Task 7; títulos de tela passam a usar `PageHeader(eyebrow: …)` quando houver contexto natural (mês, igreja). Rodar `flutter analyze` após cada domínio.
- [ ] **Step 4:** apagar `app_colors.dart`; teste → PASS; `flutter test` inteiro PASS; analyze limpo.
- [ ] **Step 5: Screenshots** claro/escuro × 390/1280 de dashboard, pessoas, escalas e um formulário. Exige o `base_api` rodando (`docker compose up -d postgres && ./mvnw spring-boot:run` no projeto `base_api`); se não estiver disponível, registrar isso no resumo e validar só por testes.
- [ ] **Step 6: Commit** `refactor(screens): migrar telas para tokens e remover AppColors`.

### Task 9: Ícone do app e favicon

**Files:**
- Create: `assets/brand/app_icon.png` (1024×1024: fundo `#000000`, `b.svg` branco com 22% de margem), `assets/brand/app_icon_foreground.png` (1024, transparente, B branco com 30% de margem)
- Modify: `pubspec.yaml` (dev_dependency `flutter_launcher_icons` + bloco de config), `web/index.html` (`<meta name="theme-color" content="#000000">`), `web/manifest.json` (`background_color`/`theme_color` `#000000`, `name`/`short_name` "Base Church")
- Generated: `web/favicon.png`, `web/icons/*`, `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`

- [ ] **Step 1:** renderizar os dois PNGs a partir de `b.svg` (HTML local com o SVG + screenshot do Playwright em 1024×1024, `omitBackground` para o transparente).
- [ ] **Step 2:** config `flutter_launcher_icons`: `android: true`, `ios: true`, `remove_alpha_ios: true`, `image_path: assets/brand/app_icon.png`, `adaptive_icon_background: "#000000"`, `adaptive_icon_foreground: assets/brand/app_icon_foreground.png`, `web: {generate: true, image_path: assets/brand/app_icon.png, background_color: "#000000", theme_color: "#000000"}`. Rodar `dart run flutter_launcher_icons`.
- [ ] **Step 3:** `flutter build web` e conferir favicon/aba no Playwright; `flutter analyze` e `flutter test` limpos.
- [ ] **Step 4: Commit** `feat(brand): ícone do app e favicon com o monograma B`.

### Task 10: Fechamento

- [ ] Atualizar `CLAUDE.md`: seção "Layout" passa a citar `docs/BRAND.md`, `context.brand`, `lib/widgets/brand/`, Archivo + DM Sans (remover Syne) e a regra de não usar cor fixa.
- [ ] `flutter analyze`, `flutter test`, `flutter build web --release --dart-define=API_URL=https://example/api` → OK.
- [ ] Commit `docs: CLAUDE.md com o novo sistema de marca`.
