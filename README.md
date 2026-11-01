# Base Church — Gestão

App Flutter (iOS, Android e Web) do sistema de gestão da Base Church. Consome a API Spring Boot (`base_api`).

## Stack

- Flutter · Dart 3
- `go_router` — navegação
- `provider` — estado (auth + serviços)
- `google_fonts` — DM Sans + Syne
- `share_plus` — exportação (TXT, Markdown, Excel como texto)
- API Spring Boot (`base_api`)

## Começar

```bash
flutter pub get
flutter run
```

O app precisa da `base_api` rodando (veja abaixo).

## Configuração

`API_URL` é definida em tempo de compilação via `--dart-define` (ver `lib/config/app_config.dart`). Padrão: `http://localhost:8080/api`. Em release ela é obrigatória.

```bash
# desenvolvimento contra a API local
flutter run --dart-define=API_URL=http://localhost:8080/api

# produção
flutter build web --release --dart-define=API_URL=https://<servidor>/api
```

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
  config/       # API URL
  models/       # Entidades
  navigation/   # Menu e filtros
  providers/    # Auth
  router/       # go_router
  screens/      # Telas
  services/     # HTTP
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
| Exportação | gerada no app e compartilhada via share |
