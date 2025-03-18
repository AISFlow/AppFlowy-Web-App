FROM node:lts-bookworm AS prepares

ARG VERSION=main
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /prepares/

RUN corepack enable && \
    pnpm i -g pnpm@8.5.0 && \
    pnpm config set store-dir /pnpm/store

RUN git clone --branch ${VERSION} https://github.com/AppFlowy-IO/AppFlowy-Web.git .

ENV AF_BASE_URL=AF_BASE_URL_PLACEHOLDER
ENV AF_GOTRUE_URL=AF_GOTRUE_URL_PLACEHOLDER

RUN pnpm install && \
    pnpm run build && \
    rm -rf node_modules

WORKDIR /AppFlowy-Cloud/

RUN git clone --branch ${VERSION} https://github.com/AppFlowy-IO/AppFlowy-Cloud.git .

FROM nginx:bookworm AS final

COPY --link --from=prepares /prepares/dist/ /usr/share/nginx/html/
COPY --link --from=prepares /AppFlowy-Cloud/docker/web/nginx.conf /etc/nginx/nginx.conf
COPY --link --from=prepares --chmod=755 /AppFlowy-Cloud/docker/web/env.sh /docker-entrypoint.d/env.sh