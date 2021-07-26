FROM registry.access.redhat.com/ubi7/ruby-27

USER root

# Configure users and groups
RUN groupadd -g 40054 alma && \
    useradd -r -s /sbin/nologin -M -u 40054 -g alma alma && \
    groupadd -g 40061 bfs && \
    usermod -u 40061 -g bfs -G alma -l bfs default && \
    find / -user 1001 -exec chown -h bfs {} \; || true

COPY --chown=bfs Gemfile* ./
RUN bundle install --system
COPY --chown=bfs . .

USER bfs
WORKDIR /opt/app-root/src/data
CMD ["/opt/app-root/src/bin/wrapper.sh"]
