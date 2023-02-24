FROM registry.access.redhat.com/ubi8/ruby-27

USER root

# Configure users and groups
RUN groupadd -g 40054 alma && \
    useradd -r -s /sbin/nologin -M -u 40054 -g alma alma && \
    groupadd -g 40061 bfs && \
    usermod -u 40061 -g bfs -G alma -l bfs default && \
    find / -user 1001 -exec chown -h bfs {} \; || true

COPY --chown=bfs Gemfile* .ruby-version ./
RUN bundle install --system
COPY --chown=bfs . .

USER bfs
ENTRYPOINT ["/opt/app-root/src/bin/bfs"]
CMD ["help"]
