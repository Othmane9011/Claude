# ---------- base (Debian, pas Alpine) ----------
FROM node:20-bookworm-slim AS base
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ---------- deps (avec dev pour builder) ----------
FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm config set legacy-peer-deps true
RUN npm ci
# Prisma client pour la compilation TS
COPY prisma ./prisma
RUN npx prisma@5.22.0 generate

# Installe Chromium + libs DANS CETTE ÉTAPE et force le chemin /ms-playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npx --yes playwright@1.48.0 install --with-deps chromium

# ---------- build ----------
FROM deps AS builder
WORKDIR /app
COPY . .
RUN npx nest build

# ---------- prod-deps (runtime sans dev) ----------
FROM base AS prod-deps
WORKDIR /app
COPY package*.json ./
RUN npm config set legacy-peer-deps true
RUN npm ci --omit=dev
COPY prisma ./prisma
RUN npx prisma@5.22.0 generate

# ---------- run ----------
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

# Empêche un re-téléchargement des navigateurs en runtime
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

# Dépendances système requises par Chromium dans cette étape finale
RUN npx --yes playwright@1.48.0 install-deps chromium

# node_modules prod + build
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=builder   /app/dist         ./dist
COPY --from=builder   /app/prisma       ./prisma

# navigateurs Playwright déjà installés en étape deps
COPY --from=deps      /ms-playwright    /ms-playwright

COPY package*.json ./

EXPOSE 3000
CMD ["sh","-lc","npx prisma@5.16.2 migrate deploy && node dist/src/main.js"]
