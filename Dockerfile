# Build stage: Flutter clonado na versão exata do projeto (a imagem da cirruslabs no GHCR parou na 3.44,
# e o pubspec exige Dart ^3.13.1).
FROM debian:trixie-slim AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl unzip xz-utils ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG FLUTTER_VERSION=3.47.1
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
ARG API_URL=https://api.veigagustavo.com.br/api
# Build de release sem API_URL abre uma tela de erro (lib/config/app_config.dart).
RUN flutter build web --release --dart-define=API_URL=${API_URL}

FROM nginx:1.27-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/healthz || exit 1
