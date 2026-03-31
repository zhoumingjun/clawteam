# OpenClaw Gateway + CLI
# Debian slim (Alpine 与 @matrix-org/matrix-sdk-crypto-nodejs 原生库不兼容)
# 构建时 patch：① 出站 mention ② 入站 formatted_body ③ 入站信任 m.mentions
FROM node:22-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl bash openssl python3 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/openclaw-app
COPY patches/ /tmp/openclaw-mention-patch/
RUN npm init -y >/dev/null 2>&1 \
  && npm install --omit=dev \
    openclaw@2026.3.28 \
    @matrix-org/matrix-sdk-crypto-nodejs@0.4.0 \
  && node /tmp/openclaw-mention-patch/patch-openclaw-matrix-mentions.mjs \
  && node /tmp/openclaw-mention-patch/patch-openclaw-matrix-inbound-formatted-mentions.mjs \
  && node /tmp/openclaw-mention-patch/patch-openclaw-matrix-trust-m-mentions.mjs \
  && rm -rf /tmp/openclaw-mention-patch

ENV PATH="/opt/openclaw-app/node_modules/.bin:${PATH}"
ENV NODE_PATH="/opt/openclaw-app/node_modules"

WORKDIR /app

CMD ["tail", "-f", "/dev/null"]
