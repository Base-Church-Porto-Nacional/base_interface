# Base Church — Gestão

App Flutter (iOS, Android e Web) do sistema de gestão da Base Church. Consome a API Spring Boot (`base_api`) ou roda com dados mock locais.

## Stack

- Flutter · Dart 3
- `go_router` — navegação
- `provider` — estado (auth + serviços)
- `google_fonts` — DM Sans + Syne
- `share_plus` — exportação (TXT, Markdown, Excel como texto)
- Mock local ou API Spring Boot

## Começar

```bash
flutter pub get
flutter run
```

Login mock: `admin` / `admin123`

## Configuração

Em `lib/config/app_config.dart`:

| Constante | Descrição | Padrão |
|-----------|-----------|--------|
| `useMock` | `true` = dados locais | `true` |
| `apiUrl` | Base da API | `http://localhost:8080/api` |

Para API real, altere `useMock` para `false` e aponte `apiUrl` para o backend.

Com a API:

```bash
# em base_api
docker compose up -d postgres
./mvnw spring-boot:run
```

Login da API: `admin` / `admin123`

## Telas

- Login
- Dashboard (indicadores + exportação)
- Membros / Pessoas (busca, filtros, exportação com histórico)
- Ficha de pessoa (perfil, jornada, histórico)
- Líderes
- Ministérios (lista + detalhe + edição)
- Placeholders: Voluntários, Escalas, Usuários, Perfil

## Design

- Paleta preto/branco/cinza (`lib/theme/`)
- Layout mobile-first: cards compactos, filtro por ícone, botão Exportar com dropdown
- Drawer lateral para navegação principal

## Estrutura

```text
lib/
  config/       # API URL, mock
  models/       # Entidades
  navigation/   # Menu e filtros
  providers/    # Auth
  router/       # go_router
  screens/      # Telas
  services/     # HTTP + mocks
  theme/        # Cores e ThemeData
  utils/        # Permissões, formatação
  widgets/      # Componentes reutilizáveis
android/  ios/  web/  # Plataformas
```

## Scripts

```bash
flutter analyze
flutter test
flutter build apk
flutter build ios
```

## Mapa tela → endpoint

| Tela | Endpoints |
|------|-----------|
| Login | `POST /auth/login` |
| Pessoas | `GET/POST/PUT /pessoas` + export |
| Pessoa → Histórico | `GET /pessoas/{id}/historico` |
| Ministérios | `/ministerios` |
| Exportação | share local (mock) ou `GET /export/{recurso}` |
