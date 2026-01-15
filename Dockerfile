FROM ruby:3.3-slim AS base

# Configure users and groups
RUN groupadd -g 40054 alma && \
    useradd -s /sbin/nologin -M -u 40054 -g alma alma && \
    groupadd -g 40061 bfs && \
    useradd -u 40061 -g bfs -G alma -m bfs && \
    install -d -o bfs -g bfs -m 0700 /opt/app /home/bfs/.ssh

# Install packages common to dev/prod
RUN apt-get -y update -qq && \
    gem install bundler --version 2.5.22

# Ignore the system's platform and only install native Ruby versions
ENV BUNDLE_FORCE_RUBY_PLATFORM=true
# Prevent automatic updates to the Gemfile.lock
ENV BUNDLE_FROZEN=true
# Install Gems to the container's system-wide location
ENV BUNDLE_SYSTEM=true
# Prepend BFS script to PATH so you don't have to prefix with /opt/app/bin.
ENV PATH=/opt/app/bin:$PATH

WORKDIR /opt/app
ENTRYPOINT ["/opt/app/bin/bfs"]
CMD ["help"]

# ===============================================
# Target: development
# ===============================================
FROM base AS development

RUN apt-get -y --no-install-recommends install \
        build-essential \
        make

# Install rubygems. This step is separated from copying the
# rest of the codebase to maximize cache hits.
COPY --chown=bfs Gemfile* .ruby-version ./
RUN bundle install

# Install the rest of the codebase.
COPY --chown=bfs:bfs . .

# =================================
# Target: production
# =================================
FROM base AS production

# Copy the built codebase/dependencies from the dev stage
COPY --from=development --chown=bfs:bfs /opt/app /opt/app
COPY --from=development --chown=bfs:bfs /usr/local/bundle /usr/local/bundle

# Drop privileges
USER bfs

# Verify the installation
RUN bundle check && \
    bfs help
