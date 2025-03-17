FROM node:lts-bookworm AS prepares

ARG VERSION=main
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /prepares

RUN corepack enable && \
    pnpm i -g pnpm@8.5.0 && \
    pnpm config set store-dir /pnpm/store

RUN git clone --depth 1 --branch ${VERSION} https://github.com/AppFlowy-IO/AppFlowy-Web.git .

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install && \
    pnpm build

FROM oven/bun:latest AS base

ENV NODE_ENV=production

WORKDIR /app

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    addgroup --system nginx && \
    adduser --system --no-create-home --disabled-login --ingroup nginx nginx

RUN bun install cheerio@1.0.0-rc.12 pino pino-pretty 

COPY --link --from=prepares /prepares/ /app/
COPY --link --from=prepares /prepares/dist/ /usr/share/nginx/html/
COPY --link --from=prepares /prepares/deploy/nginx.conf /etc/nginx/nginx.conf
COPY --link --from=prepares --chmod=755 /prepares/deploy/supervisord.conf /app/supervisord.conf
COPY --link --from=prepares --chmod=755 /prepares/deploy/start.sh /app/start.sh

EXPOSE 80

CMD ["supervisord", "-c", "/app/supervisord.conf"]