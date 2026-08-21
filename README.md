# Base Church — Gestão (Frontend)

Frontend React + TypeScript do sistema de gestão. Consome a API Spring Boot (`base_api`) como fonte única da verdade: o front só monta telas, tipa DTOs e envia/recebe JSON.

## Stack

- React · TypeScript · Vite
- `fetch` tipado (`src/services/api.ts`)
- JWT em `localStorage` (`Authorization: Bearer <token>`)
- 401 → limpa sessão e redireciona para `/login`

## Começar

```bash
npm install
cp .env.example .env
npm run dev
```

Abra `http://localhost:5173`.

## Variáveis de ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `VITE_API_URL` | Base da API (com `/api`) | `http://localhost:8080/api` |
| `VITE_USE_MOCK` | `true` = dados locais; `false` = API real | `false` |

Com a API:

```bash
# em base_api
docker compose up -d postgres
./mvnw spring-boot:run
```

Login da API: `admin` / `admin123`

## Mapa tela → endpoint

| Tela | Endpoints |
|------|-----------|
| Login | `POST /auth/login` |
| Pessoas | `GET/POST/PUT /pessoas` + export |
| Pessoa → Histórico | `CRUD /pessoas/{id}/historico` |
| Pessoa → Jornada | `GET/PUT /pessoas/{id}/jornada` · catálogo `/jornada-etapas` |
| Ministérios / Serviços | `/ministerios` · `/ministerios/{id}/servicos` · `/servicos/{id}` |
| Voluntários (vínculo) | `CRUD /voluntarios` |
| Escalas | `/escalas` · `/escalas/{id}/servicos` · `/escalas/{id}/voluntarios` |
| Disponibilidade | `/disponibilidades/semanal/...` · `/disponibilidades/indisponibilidades/...` |
| Usuários / Papéis | `CRUD /usuarios` · `GET /papeis` |
| Exportação | `GET /export/{recurso}?formato=txt\|md\|xlsx` |

## Tipagem

Contratos da API em `src/types/api.ts`. Modelos de UI em `src/types/index.ts`. Mappers em `src/types/mappers.ts`.

Erros padronizados da API (`message`) são exibidos em toast/alerta via `ApiError`.

## Scripts

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Servidor de desenvolvimento |
| `npm run build` | Build de produção |
| `npm run preview` | Preview do build |
| `npm run lint` | ESLint |

## Estrutura

```text
src/
  components/   # UI e layout
  contexts/     # AuthContext
  mocks/        # Dados locais (VITE_USE_MOCK=true)
  pages/        # Telas
  routes/       # ProtectedRoute / PermissionGuard
  services/     # Camada HTTP
  styles/       # Design tokens
  types/        # DTOs e modelos
```

## Observações

- Pessoa ≠ Usuário (relação 1:0..1).
- Voluntário = vínculo `pessoa ↔ serviço` (cargo, data entrada, líder, ativo).
- Geração automática de escala ainda é stub no backend.
- Validação forte fica no backend (Bean Validation).
