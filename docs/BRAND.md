# Base Church — Guia de estilo e rebranding do app

Status: **rascunho para aprovação** · 2026-11-01
Escopo: app `base_church` (Flutter — iOS, Android e Web). Este documento é a spec do redesign: tudo o que for implementado deve estar aqui, e o que mudar aqui muda no código.

---

## 1. Essência

O app é a ferramenta de bastidor de uma igreja em rede (matriz Palmas + filiais como Porto Nacional e Arraias). Quem usa são pastores, líderes e voluntários, geralmente pelo celular, entre um culto e outro.

Referências de voz tiradas das redes (`@basechurchpalmas`, `@basechurchporto`):

- **"Uma família para sempre 🤍"** — acolhimento, nada de tom corporativo.
- **"2026 — A partir de Jesus"** — tema do ano; pode aparecer no login/splash como linha de apoio.
- Comunicação visual das redes: fotos de culto com luz de palco quente, tipografia **pesada e larga** em caixa-alta ("DISCI-PULADO", "BASE PORTO"), chips em pílula translúcidos com horários, o selo como assinatura no canto.

Tradução para o app: **simples de usar, preto e branco, com luz e vidro**. A marca aparece forte nos momentos de entrada (login, splash, topo do menu, saudação do dashboard) e sai do caminho no trabalho do dia a dia (listas, formulários, tabelas).

## 2. Princípios

1. **Preto e branco de verdade.** Só neutros. Cor apenas para estado (sucesso, aviso, erro), nunca para decorar.
2. **Híbrido.** Momentos de marca usam a linguagem do selo (Archivo larga, caixa-alta, blocos pretos com luz). Telas de trabalho usam DM Sans, superfícies limpas e hierarquia clara.
3. **Luz, sombra e vidro.** Nada chapado: superfícies têm elevação, blocos pretos têm holofote, camadas flutuantes são vidro fosco sobre luz ambiente.
4. **Funciona igual em claro e escuro.** Segue o sistema. Nenhuma tela usa cor fixa — só tokens.
5. **Toque fácil.** Alvos ≥ 48px, contraste AA no mínimo, movimento respeita "reduzir movimento".

## 3. Logo

### 3.1 Versões

| Versão | O que é | Onde usar | Arquivo |
|---|---|---|---|
| **Selo** | anel "BASE CHURCH • BASE CHURCH" + "B" central | login, splash, topo do drawer, telas vazias grandes | `assets/brand/selo.svg` |
| **Anel** | só o anel de texto | animação do login (gira) | `assets/brand/selo_anel.svg` |
| **Monograma "B"** | só o "B" | app bar compacta, avatar padrão, ícone do app, favicon | `assets/brand/b.svg` |
| PNG oficial preta / branca | arte original 1416×1406 com transparência | materiais fora do app, compartilhamento | `assets/brand/logo_preta.png`, `assets/brand/logo_branca.png` |
| PDF vetorial oficial | CorelDRAW, 2 páginas (negativo/positivo) | fonte para gerar os SVGs | `assets/brand/logo_base_church.pdf` |

Os SVGs são **monocromáticos** (um único `fill`) e pintados em runtime pelo tema via `flutter_svg` + `ColorFilter`. Um arquivo serve para claro e escuro.

### 3.2 Regras

- **Cor:** preto sobre claro, branco sobre escuro/vidro escuro. Nunca cinza, nunca colorido, nunca com gradiente *no traço*. (O avatar do Instagram usa o selo sobre luz holográfica — no app o equivalente é o selo branco sobre a luz ambiente, ver §6.3.)
- **Área de proteção:** em volta do selo, espaço livre igual a ¼ do diâmetro.
- **Tamanho mínimo:** selo ≥ 64px de diâmetro (abaixo disso o anel fica ilegível). Abaixo de 64px use o monograma "B" (mínimo 16px).
- **Não:** distorcer, girar o "B", contornar, pôr sombra no traço, recriar o letreiro com fonte, colocar sobre foto sem escurecer a foto.

## 4. Cor

### 4.1 Tokens semânticos

| Token | Claro | Escuro | Uso |
|---|---|---|---|
| `background` | `#F5F5F5` | `#000000` | fundo das telas |
| `surface` | `#FFFFFF` | `#141414` | cards, inputs |
| `surfaceRaised` | `#FAFAFA` | `#1C1C1C` | hover, zebra, e2 |
| `surfaceOverlay` | `#FFFFFF` | `#242424` | diálogos, e3 |
| `inverse` | `#000000` | `#000000` | blocos de marca — **pretos nos dois temas** |
| `onInverse` | `#FFFFFF` | `#FFFFFF` | texto/selo sobre `inverse` |
| `textPrimary` | `#0A0A0A` | `#FAFAFA` | texto principal |
| `textSecondary` | `#525252` | `#A3A3A3` | apoio |
| `textMuted` | `#6E6E6E` | `#8C8C8C` | placeholder, metadado (≥ 4.5:1) |
| `border` | `#E5E5E5` | `#262626` | divisórias |
| `borderStrong` | `#D4D4D4` | `#404040` | inputs, outlined |
| `primary` / `onPrimary` | `#000000` / `#FFFFFF` | `#FFFFFF` / `#000000` | botão primário (inverte no escuro) |
| `focus` | `#000000` | `#FFFFFF` | anel de foco (2px) |
| `success` / `successBg` | `#167A45` / `#E7F4EC` | `#4ADE80` / `#0F2A1A` | só estado |
| `warning` / `warningBg` | `#8A6500` / `#FFF6DB` | `#FACC15` / `#2A2205` | só estado |
| `danger` / `dangerBg` | `#B42318` / `#FCE8E6` | `#F87171` / `#2D0F0D` | só estado |

### 4.2 Escala primitiva (referência)

`black #000` · `n950 #0A0A0A` · `n900 #141414` · `n850 #1C1C1C` · `n800 #242424` · `n750 #262626` · `n700 #404040` · `n500 #6E6E6E` · `n450 #8C8C8C` · `n400 #A3A3A3` · `n300 #D4D4D4` · `n200 #E5E5E5` · `n100 #F5F5F5` · `n50 #FAFAFA` · `white #FFF`

Semânticos apontam para primitivos; telas usam **apenas semânticos**.

## 5. Tipografia

| Estilo | Fonte | Tamanho/altura | Peso | Detalhe | Uso |
|---|---|---|---|---|---|
| `hero` | Archivo Expanded (`wdth 125`) | 36/40 | 900 | CAIXA-ALTA, tracking −0.5 | "BEM-VINDO", saudação do dashboard |
| `pageTitle` | Archivo Expanded | 28/32 | 900 | CAIXA-ALTA | título de página |
| `stat` | Archivo Expanded | 32/36 | 800 | algarismos tabulares | números do dashboard |
| `eyebrow` | Archivo Expanded | 12/16 | 700 | CAIXA-ALTA, tracking +1.2 | rótulo acima de títulos: `ESCALAS · NOVEMBRO` |
| `titleLarge` | DM Sans | 20/28 | 600 | | título de card/diálogo |
| `titleMedium` | DM Sans | 16/24 | 600 | | item de lista |
| `bodyLarge` | DM Sans | 16/24 | 400 | | texto corrido |
| `bodyMedium` | DM Sans | 14/20 | 400 | | padrão de UI |
| `bodySmall` | DM Sans | 12/16 | 400 | `textSecondary` | legenda |
| `label` | DM Sans | 14/20 | 600 | | botões, chips |

- **Archivo** (OFL) entra **embutida** em `assets/fonts/Archivo[wdth,wght].ttf` e é usada com `FontVariation('wdth', 125)` + `FontVariation('wght', …)`, porque o `google_fonts` não expõe o eixo de largura. Fallback se o eixo falhar no web: `Archivo Black`.
- **DM Sans** continua via `google_fonts`. **Syne sai.**
- Archivo nunca em texto corrido nem abaixo de 12px.
- Abaixo de 600px `pageTitle` cai para 22px e `hero` para 28px. Títulos (`BrandHeadline`) nunca partem palavra: se a palavra mais longa não cabe, o tamanho reduz até ela caber, sem ficar abaixo de 12px renderizados.

## 6. Profundidade: elevação, luz e vidro

### 6.1 Elevação

| Nível | Uso | Claro (sombras sobrepostas, preto) | Escuro |
|---|---|---|---|
| `e0` | linha de tabela, item plano | só `border` | só `border` |
| `e1` | card, tile | `0 1 2 /4%` + `0 2 8 /6%` | `surface` + filete topo branco 6% |
| `e2` | hover, menu, dropdown | `0 2 4 /6%` + `0 8 24 /10%` | `surfaceRaised` + filete 7% + sombra preta 50% |
| `e3` | diálogo, card do login, bottom sheet | `0 4 8 /8%` + `0 24 48 /18%` | `surfaceOverlay` + filete 8% + sombra preta 60% |

No escuro a sombra some sobre preto, então **quanto mais alto, mais clara a superfície** e a quina de cima ganha um filete de luz (borda superior 1px branco com a opacidade indicada).

### 6.2 Holofote nos blocos `inverse`

Drawer, header de marca e painel do login: gradiente radial `#2A2A2A → #000000` (centro no alto, raio ~120% da largura) + grão de ruído 3% (`assets/brand/grain.png`, 128×128, repetido). Nunca preto chapado.

### 6.3 Luz ambiente

O vidro precisa de algo atrás. `AmbientBackground` pinta 2–3 manchas de luz grandes e desfocadas (radiais, sem borda) sobre o `background`:

- **Escuro:** manchas brancas a 6–10% sobre preto — lembra a luz de palco das fotos dos cultos.
- **Claro:** manchas cinza `#D4D4D4` a 40–60% sobre `#F5F5F5` — sutil, só para o vidro ter textura.
- Posição fixa por tela (não segue o scroll); no login as manchas se movem devagar (deriva de 20s), desligado com "reduzir movimento".

### 6.4 Material glass

Vidro fosco aplicado **só a camadas que flutuam sobre conteúdo**:

| Onde | Vidro? |
|---|---|
| App bar (sobre conteúdo rolando) | ✅ |
| Barra de navegação inferior / drawer | ✅ |
| Card do login | ✅ |
| Diálogos, bottom sheets, menus | ✅ |
| Chips "pílula" de informação sobre foto/cabeçalho (estilo das redes) | ✅ |
| Cards de lista, tabelas, campos de formulário | ❌ — `surface` sólida (legibilidade + performance) |

Receita do `GlassSurface`:

| Propriedade | Claro | Escuro |
|---|---|---|
| Desfoque (`ImageFilter.blur`) | σ 24 | σ 24 |
| Tinta | branco 70% | `#141414` 55% |
| Borda | 1px, gradiente branco 80% (topo) → branco 20% (base) | 1px, branco 14% (topo) → branco 4% (base) |
| Brilho interno | gradiente linear branco 30% → 0% no terço superior | branco 6% → 0% |
| Sombra | a do nível (`e2` ou `e3`) | a do nível |
| Raio | 16 (painéis), 999 (pílulas), 0 (barras encostadas na borda) | idem |

Fallback: se o SO pedir **reduzir transparência**, ou no web quando o renderizador não suportar o backdrop, o vidro vira `surfaceOverlay` sólido com a mesma borda e sombra.

**Biblioteca — decisão:** implementação própria com `BackdropFilter` + `ClipRRect` + `DecoratedBox` (nativo do Flutter, funciona em iOS, Android e Web, sem dependência).

Avaliadas e não adotadas agora:
- `liquid_glass_renderer` 1.0.0-dev.2 — o "liquid glass" estilo iOS 26 de verdade (refração), mas é **pré-release**, depende de Impeller + Flutter GPU (preview) e no **web renderiza só "FakeGlass"** — e o deploy principal é web. Reavaliar quando sair 1.0 estável, como upgrade só para iOS/Android atrás do mesmo `GlassSurface`.
- `glassmorphism` 4.0.0 / `glass_forge` 0.1.1 / `oc_liquid_glass` 0.3.0 — empacotam o mesmo `BackdropFilter`; não justificam a dependência.

## 7. Forma, espaço e movimento

- **Raio:** `0` blocos de marca · `8` cards, botões, inputs · `16` painéis de vidro e diálogos · `999` pílulas · círculo para avatar e selo.
- **Espaço (base 4):** 4 · 8 · 12 · 16 · 24 · 32 · 48. Margem lateral 16 (< 600px) e 24 (≥ 600px). Conteúdo máx. 1200px.
- **Alvos de toque:** ≥ 48×48. Inputs e botões principais com 48 de altura.
- **Movimento:** 150ms `easeOut` para hover/press; 250ms `easeOutCubic` para entrada de diálogo/sheet (fade + 8px de subida); anel do selo no login: 1 volta/60s linear. Card em hover sobe 2px e vai de `e1` → `e2`; botão pressionado desce 1px. Tudo desligado com `MediaQuery.disableAnimations`.
- **Ícones:** Material Symbols *outlined*, 20–24px, `textSecondary`.

## 8. Componentes de marca

Ficam em `lib/widgets/brand/` e são a única forma de as telas falarem a linguagem de marca.

| Widget | Responsabilidade |
|---|---|
| `BrandSeal({double size, bool spinning = false, Color? color})` | selo SVG pintado pelo tema; `spinning` gira só o anel |
| `BrandMark({double size, Color? color})` | monograma "B" |
| `GlassSurface({child, radius, level, padding})` | receita da §6.4 com fallback |
| `AmbientBackground({child, animated = false})` | luz ambiente da §6.3 |
| `SpotlightBlock({child})` | bloco `inverse` com holofote + grão (§6.2) |
| `PageHeader({eyebrow, title, actions})` | cabeçalho de página com `eyebrow` + `pageTitle` |
| `StatTile({label, value, icon})` | número grande do dashboard, `e1`, hover `e2` |
| `InfoPill({icon, text})` | pílula de vidro para horários/locais (estilo das redes) |

Tokens ficam em `lib/theme/`: `app_tokens.dart` (primitivos), `brand_colors.dart` (`ThemeExtension` com os semânticos claro/escuro), `app_elevation.dart` (sombras por nível e tema), `app_typography.dart`, `app_theme.dart` (`light` e `dark`). `AppColors` estático é removido no fim da migração.

## 9. Telas

### 9.1 Login (prioridade 1)

```
≥ 900px                                   < 900px
┌───────────────────┬──────────────────┐  ┌──────────────────────┐
│ SpotlightBlock    │ AmbientBackground│  │ SpotlightBlock ~40%  │
│ + luz ambiente    │                  │  │     ( selo 120 )     │
│                   │  ┌────────────┐  │  │                      │
│   ( selo 240 )    │  │ BEM-VINDO  │  │  │ ┌──────────────────┐ │
│   anel girando    │  │ Entre com  │  │  │ │ GlassSurface e3  │ │ ← sobe 48px
│                   │  │ sua conta  │  │  │ │ BEM-VINDO        │ │   sobre o painel
│ 2026 — A PARTIR   │  │ [Usuário ] │  │  │ │ [Usuário]        │ │
│ DE JESUS          │  │ [Senha  👁]│  │  │ │ [Senha  👁]      │ │
│                   │  │ [ ENTRAR ] │  │  │ │ [ ENTRAR ]       │ │
│                   │  └────────────┘  │  │ └──────────────────┘ │
└───────────────────┴──────────────────┘  └──────────────────────┘
```

- Card do formulário é `GlassSurface` `e3`, raio 16, máx. 400px.
- Título `hero` "BEM-VINDO"; subtítulo `bodyMedium` "Entre com sua conta".
- Comportamento atual preservado (snackbar de erro, Enter envia, mostrar/ocultar senha, loading no botão).

### 9.2 Splash / carregamento inicial
`SpotlightBlock` tela cheia + `BrandSeal` 120 girando + barra fina de progresso indeterminada. Substitui o spinner solto do `_init()`.

### 9.3 Shell (app bar + drawer)
- App bar: `GlassSurface` encostado no topo (raio 0) sobre a `AmbientBackground` do shell, `BrandMark` 24 + título `titleLarge`. O conteúdo **não** rola por baixo da barra (exigiria refazer o padding das 31 telas com `PageHeader`); o vidro fica visível pela luz ambiente.
- Perfil e saída: avatar abre `/perfil` e "Sair" fica ao lado. Em telas < 400px ou com fonte > 130%, "Sair" vai para o menu do avatar (Perfil · Sair) para a barra caber sem cortar; o seletor de igreja encolhe até 88px e chega a 260px em telas ≥ 900px.
- Drawer: `SpotlightBlock` com `BrandSeal` 72 + nome da igreja selecionada + papel do usuário em `eyebrow`. Itens são só texto (o menu não tem ícones); item ativo: pílula branca 8% com texto em peso 600, anunciado como selecionado.

### 9.4 Dashboard
`hero` com saudação ("BOA NOITE, GUSTAVO"), `eyebrow` com a igreja selecionada, grade de `StatTile` (2 colunas mobile, 4 desktop) sobre `AmbientBackground`.

### 9.5 Telas de trabalho (listas, detalhes, formulários)
`PageHeader` + conteúdo em `surface` `e1`. Sem vidro, sem Archivo fora do cabeçalho. Filtros/busca em barra fixa de vidro quando a lista rola.

### 9.6 Estados
Vazio: `BrandMark` 48 em `textMuted` + frase curta + ação. Erro: ícone `danger` + mensagem do `ApiException`. Carregando: skeleton em `surfaceRaised` com shimmer (desligado com reduzir movimento).

## 10. Acessibilidade

- Texto: contraste ≥ 4.5:1 (≥ 3:1 para ≥ 18px/600). Texto sobre vidro é verificado contra o **pior caso** do fundo (tinta do vidro sobre `#000` e sobre `#FFF`).
- Foco visível: anel `focus` 2px + 2px de afastamento em todo interativo.
- Respeitar `MediaQuery.disableAnimations`, `highContrast` (vidro vira sólido, bordas `borderStrong`) e escala de fonte até 200% sem cortar.

## 11. Implementação e verificação

Ordem (cada passo é um PR revisável):

1. **Assets e fontes** — logos em `assets/brand/`, SVGs gerados do PDF (`pdftocairo -svg` + separar anel/"B"), textura `grain.png`, Archivo variável, `flutter_svg`; testar `wdth` no web.
2. **Tokens e temas** — `ThemeExtension`, `light`/`dark`, `themeMode: ThemeMode.system`.
3. **Componentes de marca** (§8) com testes de widget (renderiza em claro/escuro, fallback do vidro).
4. **Login + splash.**
5. **Shell** (app bar, drawer).
6. **Dashboard.**
7. **Migração por domínio** — trocar os ~99 `Colors.*` e 18 `TextStyle` soltos por tokens, um domínio por vez.
8. **Ícone do app e favicon** a partir do "B".

Verificação em cada passo: `flutter analyze` sem novos avisos, `flutter test`, e screenshots via Playwright do build web em **claro e escuro × 390px e 1280px**, antes/depois.

## 12. Decisões em aberto

1. **Acento quente das redes.** O Instagram usa laranja `#D9480F` nos destaques e luz quente/teal nas fotos. Este guia mantém o app 100% P&B. Opção futura: luz ambiente com leve tom quente só no login.
2. **Fonte original do letreiro do selo.** Se o designer (arquivo de Jefferson Leal) tiver a fonte, ela substitui a Archivo nos estilos `hero`/`pageTitle`/`eyebrow`.
3. **Liquid glass nativo** (`liquid_glass_renderer`) quando estável — upgrade só iOS/Android.
4. **Arquivos da logo:** os PNGs e o PDF originais precisam ser recolocados para o passo 1 (não estão mais em `~/Desktop`).
