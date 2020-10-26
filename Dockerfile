# Build stage
FROM node:lts-alpine as build

ARG PARSE_REPO="https://github.com/parse-community/parse-server.git"
ARG PARSE_VERION="4.3.0"

RUN apk update; \
  apk add git;
WORKDIR /tmp

RUN git clone $PARSE_REPO -b $PARSE_VERION

WORKDIR /tmp/parse-server

RUN npm ci

RUN npm install firebase-admin

RUN npm run build

# Release stage
FROM node:lts-alpine as release

MAINTAINER Maximilian Fischer "github@maaeps.de"

VOLUME /parse-server/cloud /parse-server/config

WORKDIR /parse-server

COPY --from=build /tmp/parse-server/package*.json ./

RUN npm ci --production --ignore-scripts

COPY --from=build /tmp/parse-server/bin bin
COPY --from=build /tmp/parse-server/public_html public_html
COPY --from=build /tmp/parse-server/views views
COPY --from=build /tmp/parse-server/lib lib
RUN mkdir -p logs && chown -R node: logs

ENV PORT=1337
USER node
EXPOSE $PORT

ENTRYPOINT ["node", "./bin/parse-server"]