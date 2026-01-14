FROM ruby:3.3-slim AS base
USER root

# Configure users and groups
RUN groupadd -g 40054 alma && \
    useradd -r -s /sbin/nologin -M -u 40054 -g alma alma && \
    useradd -u 40061 bfs && \
    groupadd -g 40061 bfs && \
    usermod -u 40061 -g bfs -G alma -l bfs default && \
    find / -user 1001 -exec chown -h bfs {} \; || true && \
    mkdir -p /opt/app && \
    chown -R bfs:bfs /opt/app

# Get list of available packages
RUN apt-get -y update -qq

COPY --chown=bfs . /opt/app

ENTRYPOINT ["/opt/app/bin/bfs"]
CMD ["help"]

# ===============================================
# Target: development
# ===============================================

FROM base AS development

USER root
 
RUN apt-get -y --no-install-recommends install \
    build-essential \
    make

USER bfs

# Base image ships with an older version of bundler
RUN gem install bundler --version 2.5.22

WORKDIR /opt/app
COPY --chown=bfs Gemfile* .ruby-version ./
RUN bundle config set force_ruby_platform true
RUN bundle config set system 'true'
RUN bundle install

# COPY --chown=bfs:bfs . .

# =================================
# Target: production
# =================================
FROM base AS production

# Copy the built codebase from the dev stage
# COPY --from=development --chown=bfs /opt/app /opt/app
COPY --from=development --chown=bfs /usr/local/bundle /usr/local/bundle

WORKDIR /opt/app
RUN bundle config set frozen 'true'
RUN bundle install --local
