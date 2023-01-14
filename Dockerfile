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
# ENV KONG_PLUGINS=oidc

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


# download kong-oidc plugin
USER root
RUN apk add --no-cache git luarocks unzip
RUN luarocks install kong-oidc

# Run kong migrations database 'kong' in postgres should already exist
RUN kong migrations bootstrap

EXPOSE 8000 8443 8001 8444

CMD ["kong", "docker-start", "-c", "/etc/kong.conf", "--vv"]
