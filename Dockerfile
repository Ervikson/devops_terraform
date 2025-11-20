# syntax=docker/dockerfile:1.9

ARG NODE_VERSION=20.17.0

FROM node:${NODE_VERSION}-bookworm AS base
WORKDIR /usr/src/app
COPY app/package*.json ./
RUN npm install --omit=dev
COPY app ./

FROM node:${NODE_VERSION}-slim AS runtime
WORKDIR /usr/src/app
ENV NODE_ENV=production
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY --from=base /usr/src/app /usr/src/app
EXPOSE 3000
CMD ["npm", "start"]
