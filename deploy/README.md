# Deploy (Docker Swarm)

| Serviço | Domínio | Imagem |
|---|---|---|
| Front (Flutter Web + nginx) | `base.veigagustavo.com.br` | `ghcr.io/base-church-porto-nacional/base_interface` |
| API (Spring Boot) + Postgres | `api.veigagustavo.com.br` | `ghcr.io/base-church-porto-nacional/base_api` |

O roteamento e o HTTPS ficam com o Traefik, na rede overlay `traefik-public`.

## 1. DNS

Registros `A` de `base.veigagustavo.com.br` e `api.veigagustavo.com.br` apontando para o IP do nó manager.

## 2. Imagens

O workflow `.github/workflows/docker.yml` de cada repositório publica no GHCR a cada push na `main` (tags `latest` e `sha-<commit>`) e em tags `v*`.
**Nenhuma imagem é publicada antes do merge na `main`** dos dois repositórios: o GitHub só aceita disparar o workflow (inclusive o *Run workflow* manual) depois que o arquivo existe na branch padrão. Depois do merge, o `latest` sai sozinho.

A URL da API vai embutida no build do front. Para trocar a URL, crie a variável `API_URL` em *Settings → Variables* do repositório.
O build do front clona o Flutter na versão do `FLUTTER_VERSION` do `Dockerfile` (3.47.1). Ao atualizar o Flutter do projeto, atualize lá também.

Build manual:

```bash
docker build --build-arg API_URL=https://api.veigagustavo.com.br/api -t ghcr.io/base-church-porto-nacional/base_interface:latest .
docker push ghcr.io/base-church-porto-nacional/base_interface:latest
```

Se os pacotes do GHCR forem privados, faça `docker login ghcr.io` no manager (com um PAT que tenha `read:packages`) e use `--with-registry-auth` no deploy.

## 3. Swarm e Traefik (apenas na primeira vez)

```bash
docker swarm init
docker network create --driver overlay --attachable traefik-public
ACME_EMAIL=voce@veigagustavo.com.br docker stack deploy -c deploy/traefik/stack.yml traefik
```

Se o servidor já tiver um Traefik, pule este passo e ajuste `TRAEFIK_NETWORK`, `TRAEFIK_ENTRYPOINT` e `TRAEFIK_CERTRESOLVER` para os nomes que ele usa.

## 4. API

No repositório `base_api`:

```bash
cp deploy/.env.example deploy/.env   # preencha DB_PASSWORD, JWT_SECRET e ADMIN_*
set -a; . deploy/.env; set +a
docker stack deploy --with-registry-auth -c deploy/stack.yml base-api
```

O CORS já libera `https://base.veigagustavo.com.br`. O admin inicial só é criado com o banco vazio. Depois do primeiro login, remova `ADMIN_SENHA` do `.env` e faça o deploy de novo.

## 5. Front

```bash
docker stack deploy --with-registry-auth -c deploy/stack.yml base-web
```

## Atualizar

```bash
docker service update --with-registry-auth --image ghcr.io/base-church-porto-nacional/base_interface:sha-<commit> base-web_web
docker service update --with-registry-auth --image ghcr.io/base-church-porto-nacional/base_api:sha-<commit> base-api_api
```

As atualizações são `start-first` e voltam sozinhas para a versão anterior se o healthcheck falhar.

## Verificar

```bash
docker stack ps base-api
docker service logs -f base-api_api
curl https://api.veigagustavo.com.br/actuator/health
curl -I https://base.veigagustavo.com.br
```

Backup do banco:

```bash
docker exec $(docker ps -qf name=base-api_postgres) pg_dump -U igreja igreja_db | gzip > backup-$(date +%F).sql.gz
```
