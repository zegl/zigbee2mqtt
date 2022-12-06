# syntax=docker/dockerfile:experimental

# set base to "alpine" or "debian" to set the base os
ARG base=alpine

# The following is a multi-stage build that builds the image in 5 stages:

# release -> entrypoint-${base} -> app -> base-${base} (layer dependency)
#                                  app -> build -> base-${base} (copy dependency)

# base-alpine and base-debian both install the same packages
FROM node:18-alpine3.16 AS base-alpine
WORKDIR /app
RUN apk add --no-cache tzdata eudev tini make gcc g++ python3 linux-headers git

FROM node:18-bullseye-slim AS base-debian
WORKDIR /app
RUN apt-get update && apt-get install -y udev build-essential python3 git && rm -rf /var/lib/apt/lists/*

# build is base layer agnostic
FROM base-${base} AS build

COPY vendor/zigbee-herdsman /app/vendor/zigbee-herdsman
WORKDIR /app/vendor/zigbee-herdsman
RUN --mount=type=cache,target=/app/vendor/zigbee-herdsman/node_modules \
    npm ci --no-audit --no-update-notifier&& npm rebuild --build-from-source && npm run build

COPY vendor/zigbee-herdsman-converters /app/vendor/zigbee-herdsman-converters
WORKDIR /app/vendor/zigbee-herdsman-converters
RUN --mount=type=cache,target=/app/vendor/zigbee-herdsman-converters/node_modules \
    npm ci --no-audit --no-update-notifier && npm rebuild --build-from-source

WORKDIR /app
COPY package*.json tsconfig.json index.js ./
COPY lib ./lib

# COPY vendor/zigbee-herdsman/package.json ./vendor/zigbee-herdsman/package.json
# COPY vendor/zigbee-herdsman/package-lock.json ./vendor/zigbee-herdsman/package-lock.json
# COPY vendor/zigbee-herdsman/node_modules ./vendor/zigbee-herdsman/node_modules

RUN --mount=type=cache,target=/app/node_modules \
    npm ci --no-audit --no-update-notifier 
RUN --mount=type=cache,target=/app/node_modules \
    npm rebuild --build-from-source
RUN --mount=type=cache,target=/app/node_modules \
    npm run build

# app is base layer agnostic
FROM base-${base} AS app

WORKDIR /app
COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/vendor /app/vendor
COPY --from=build /app/dist /app/dist

# COPY dist ./dist
COPY package.json LICENSE index.js data/configuration.yaml ./

COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN mkdir /app/data

ARG COMMIT
RUN echo "$COMMIT" > dist/.hash

ENV NODE_ENV production

FROM app AS entrypoint-alpine
ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "/usr/bin/tini", "--", "node", "index.js"]

FROM app AS entrypoint-debian
ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "node", "index.js"]

FROM entrypoint-${base} AS release
# This is our final layer! :-)