FROM registry.access.redhat.com/ubi7/ruby-27

# Install app dependencies/source code
USER root
COPY Gemfile* ./
RUN bundle install --system
COPY . .

USER default

# Set a friendly entrypoint
ENTRYPOINT ["bundle", "exec", "--", "ruby", "/opt/app-root/src/src/invoice_parser.rb"]

# Files to be processed should be mounted here
WORKDIR /opt/app-root/src/data
