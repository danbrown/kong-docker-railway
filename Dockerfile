# Get base image
FROM kong:alpine

# Kong setup
ENV KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml
ENV KONG_DB_UPDATE_FREQUENCY=1m
ENV KONG_ADMIN_LISTEN="0.0.0.0:8001, 0.0.0.0:8444 ssl"

ARG KONG_PASSWORD
ENV KONG_PASSWORD $KONG_PASSWORD

ENV KONG_PROXY_ACCESS_LOG=/dev/stdout
ENV KONG_ADMIN_ACCESS_LOG=/dev/stdout
ENV KONG_PROXY_ERROR_LOG=/dev/stderr
ENV KONG_ADMIN_ERROR_LOG=/dev/stderr
ENV KONG_PLUGINS="bundled,oidc"

# Kong Setup database
ARG KONG_DATABASE="postgres"
ENV KONG_DATABASE $KONG_DATABASE

ARG PGHOST
ARG PGPASSWORD
ARG PGPORT
ARG PGUSER

ARG KONG_PG_HOST
ENV KONG_PG_HOST $PGHOST
# RUN echo $KONG_PG_HOST

ARG KONG_PG_PORT
ENV KONG_PG_PORT $PGPORT
# RUN echo $KONG_PG_PORT

ARG KONG_PG_PASSWORD
ENV KONG_PG_PASSWORD $PGPASSWORD
# RUN echo $KONG_PG_PASSWORD

ARG KONG_PG_USER
ENV KONG_PG_USER $PGUSER
# RUN echo $KONG_PG_USER

# Setup kong.yml
COPY ./kong.yml /usr/local/kong/declarative/kong.yml

# Setup kong.conf custom config
COPY kong.conf /etc/kong.conf
RUN kong check /etc/kong.conf


# download kong-oidc and jwt plugin
USER root
ENV OIDC_PLUGIN_VERSION=1.3.0-3
ENV JWT_PLUGIN_VERSION=1.1.0-1

RUN apk update && apk add git unzip luarocks
RUN luarocks install kong-oidc
RUN git clone --branch v${OIDC_PLUGIN_VERSION} https://github.com/revomatico/kong-oidc.git
WORKDIR /kong-oidc
RUN mv kong-oidc.rockspec kong-oidc-${OIDC_PLUGIN_VERSION}.rockspec
RUN luarocks make kong-oidc-${OIDC_PLUGIN_VERSION}.rockspec
RUN luarocks pack kong-oidc ${OIDC_PLUGIN_VERSION} \
  && luarocks install kong-oidc-${OIDC_PLUGIN_VERSION}.all.rock

WORKDIR /
RUN git clone --branch 20200505-access-token-processing https://github.com/BGaunitz/kong-plugin-jwt-keycloak.git
WORKDIR /kong-plugin-jwt-keycloak
RUN luarocks make kong-plugin-jwt-keycloak-${JWT_PLUGIN_VERSION}.rockspec
RUN luarocks pack kong-plugin-jwt-keycloak ${JWT_PLUGIN_VERSION} \
  && luarocks install kong-plugin-jwt-keycloak-${JWT_PLUGIN_VERSION}.all.rock
USER kong

# Run kong migrations database 'kong' in postgres should already exist
RUN kong migrations bootstrap

EXPOSE 8000 8443 8001 8444

CMD ["kong", "docker-start", "-c", "/etc/kong.conf", "--vv"]
