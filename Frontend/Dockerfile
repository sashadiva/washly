# Washly Flutter web – production image for Railway/static hosting.
#
# Stage 1: build the Flutter web bundle. The public API URL is injected at
# build time via the API_BASE_URL build arg (Railway: set it as a build
# variable on the frontend service), baked into the compiled app.
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# The backend API base URL, e.g. https://washly-backend.up.railway.app/api
ARG API_BASE_URL=""
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

# Stage 2: serve the static build with a tiny Node static server that honors
# Railway's $PORT and supports SPA fallback (so deep links load index.html).
FROM node:22-slim AS serve
WORKDIR /app
RUN npm install -g serve
COPY --from=build /app/build/web ./web
# Railway sets PORT; serve binds to it. -s = single-page-app fallback.
ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "serve -s web -l ${PORT}"]
