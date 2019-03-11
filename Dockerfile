FROM node:10.15.1-stretch AS test

RUN apt-get update \
    && apt-get install -y jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm ci || cat npm-debug.log

COPY .babelrc ./
COPY e2e ./e2e
COPY src ./src

FROM test AS build
RUN npm run build
RUN npm run export

FROM nginx:1.14.2-alpine AS dist
COPY etc/nginx/conf.d /etc/nginx/conf.d
COPY --from=build /usr/src/app/dist /usr/share/app/dist
