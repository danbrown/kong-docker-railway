# Get base image
FROM kong/kong-gateway

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

# kong manager gui setup
ARG KONG_ADMIN_GUI_URL="http://127.0.0.1:8002/manager"
ENV KONG_ADMIN_GUI_URL $KONG_ADMIN_GUI_URL
ARG KONG_ADMIN_GUI_PATH="/manager"
ENV KONG_ADMIN_GUI_PATH $KONG_ADMIN_GUI_PATH
ARG KONG_ADMIN_GUI_LISTEN="0.0.0.0:8002, 0.0.0.0:8445 ssl"
ENV KONG_ADMIN_GUI_LISTEN $KONG_ADMIN_GUI_LISTEN

# kong manager gui setup
ENV KONG_ENFORCE_RBAC="on"
ENV KONG_ADMIN_GUI_AUTH="basic-auth"
ARG SESSION_SECRET
ENV SESSION_SECRET $SESSION_SECRET
ENV KONG_ADMIN_GUI_SESSION_CONF='{"cookie_name":"KONG_SESSION", "secret":"'
ENV KONG_ADMIN_GUI_SESSION_CONF=$KONG_ADMIN_GUI_SESSION_CONF$SESSION_SECRET
ENV KONG_ADMIN_GUI_SESSION_CONF=$KONG_ADMIN_GUI_SESSION_CONF'" }'
RUN echo $KONG_ADMIN_GUI_SESSION_CONF

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
COPY ./kong.yml /kong/declarative/kong.yml
ARG KONG_DECLARATIVE_CONFIG="/kong/declarative/kong.yml"
ENV KONG_DECLARATIVE_CONFIG $KONG_DECLARATIVE_CONFIG

# Setup kong.conf custom config
COPY kong.conf /etc/kong/kong.conf
RUN kong check /etc/kong/kong.conf


# download kong-oidc and jwt plugin
USER root
ENV OIDC_PLUGIN_VERSION=1.3.0-3
ENV JWT_PLUGIN_VERSION=1.1.0-1

RUN apt update
RUN apt install git unzip luarocks -y
RUN luarocks install kong-oidc
RUN git clone --branch v${OIDC_PLUGIN_VERSION} https://github.com/revomatico/kong-oidc.git
WORKDIR /kong-oidc
RUN mv kong-oidc.rockspec kong-oidc-${OIDC_PLUGIN_VERSION}.rockspec
RUN luarocks make kong-oidc-${OIDC_PLUGIN_VERSION}.rockspec

WORKDIR /
RUN git clone --branch 20200505-access-token-processing https://github.com/BGaunitz/kong-plugin-jwt-keycloak.git
WORKDIR /kong-plugin-jwt-keycloak
RUN luarocks make kong-plugin-jwt-keycloak-${JWT_PLUGIN_VERSION}.rockspec
WORKDIR /
USER kong

# Run kong migrations database 'kong' in postgres should already exist
RUN kong migrations bootstrap
RUN kong migrations finish
RUN kong migrations up

EXPOSE 8000 8443 8001 8444 8002 8445

CMD ["kong", "docker-start", "-c", "/etc/kong/kong.conf", "--vv"]
