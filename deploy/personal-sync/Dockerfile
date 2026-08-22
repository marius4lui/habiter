FROM node:24.13.1-bookworm-slim@sha256:a81a03dd965b4052269a57fac857004022b522a4bf06e7a739e25e18bce45af2 AS build

WORKDIR /workspace
RUN corepack enable && corepack prepare pnpm@11.21.0 --activate
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/sync-auth/package.json packages/sync-auth/package.json
COPY packages/sync-core/package.json packages/sync-core/package.json
COPY packages/sync-d1/package.json packages/sync-d1/package.json
COPY packages/sync-http/package.json packages/sync-http/package.json
COPY packages/sync-service/package.json packages/sync-service/package.json
COPY packages/sync-sqlite/package.json packages/sync-sqlite/package.json
RUN pnpm install --frozen-lockfile
COPY packages/sync-auth packages/sync-auth
COPY packages/sync-core packages/sync-core
COPY packages/sync-http packages/sync-http
COPY packages/sync-service packages/sync-service
COPY packages/sync-sqlite packages/sync-sqlite
RUN pnpm --filter @habiter/sync-service build

FROM node:24.13.1-bookworm-slim@sha256:a81a03dd965b4052269a57fac857004022b522a4bf06e7a739e25e18bce45af2 AS runtime

LABEL org.opencontainers.image.title="Habiter Personal Sync Beta" \
      org.opencontainers.image.description="Single-account Habiter Personal Sync Beta service" \
      org.opencontainers.image.source="https://github.com/marius4lui/habiter" \
      org.opencontainers.image.version="1.12.0-beta" \
      dev.habiter.distribution="beta"

ENV NODE_ENV=production \
    HABITER_SYNC_DATA_DIR=/var/lib/habiter-sync \
    HABITER_SYNC_BACKUP_DIR=/var/lib/habiter-sync-backups \
    HABITER_SYNC_HOST=0.0.0.0 \
    HABITER_SYNC_PORT=8787

WORKDIR /app
RUN install -d -o node -g node -m 0700 /var/lib/habiter-sync /var/lib/habiter-sync-backups
COPY --from=build --chown=node:node /workspace/packages/sync-service/dist/service.mjs /app/service.mjs

USER node:node
EXPOSE 8787
VOLUME ["/var/lib/habiter-sync", "/var/lib/habiter-sync-backups"]
STOPSIGNAL SIGTERM
ENTRYPOINT ["node", "/app/service.mjs"]
CMD ["serve"]
