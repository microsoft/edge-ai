FROM node:22-slim AS builder

WORKDIR /app

ARG SPEECH_PROVIDER=azure

COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

COPY tsconfig.json tsconfig.server.json ./
COPY src/ src/
COPY public/ public/

RUN npx tsc --build tsconfig.server.json
RUN npx esbuild src/client/index.tsx \
    --bundle --platform=browser --target=esnext \
    --outdir=public/dist --jsx=automatic --minify \
    --define:__SPEECH_PROVIDER__="\"${SPEECH_PROVIDER}\""

FROM node:22-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production

RUN adduser --disabled-password --gecos '' appuser

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public/dist ./public/dist
COPY --from=builder /app/public/index.html ./public/
COPY --from=builder /app/public/voice-live-worklet.js ./public/
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

USER appuser

EXPOSE 3978

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD node -e "fetch('http://localhost:3978/api/healthz').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["node", "dist/server/index.js"]
