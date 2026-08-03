# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

ARG NODE_IMAGE=node:22-bookworm-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3

FROM ${NODE_IMAGE} AS base
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      libssl3=3.0.20-1~deb12u2 \
      openssl=3.0.20-1~deb12u2 \
    && rm -rf /var/lib/apt/lists/*

FROM base AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --no-audit --no-fund

COPY nest-cli.json prisma.config.ts tsconfig.json tsconfig.build.json ./
COPY prisma ./prisma
COPY scripts ./scripts
COPY src ./src

RUN DATABASE_URL=postgresql://build:build@localhost:5432/build \
    npx prisma generate
RUN npm run build
RUN npm prune --omit=dev --ignore-scripts --no-audit --no-fund

FROM base AS runtime
ARG APP_RELEASE=local

LABEL org.opencontainers.image.title="Sosedi backend" \
      org.opencontainers.image.version="${APP_RELEASE}"

ENV NODE_ENV=production \
    PORT=3000 \
    TRUSTED_PROXY_IPS=127.0.0.1 \
    APP_RELEASE="${APP_RELEASE}"

WORKDIR /app
COPY --from=build --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist

USER node
EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/api/v1/health/ready',{headers:{'x-forwarded-proto':'https'}}).then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"]

CMD ["node", "dist/src/main.js"]
