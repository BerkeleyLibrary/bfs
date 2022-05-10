module Envs
require_relative 'logging'
include Logging

#takes an array of environment variables to retrieve
def self.get_envs(secrets)
  envs = {}
  secrets.each do |env|
    if ENV[env]
      envs[env] = ENV[env]
    else
      logger.info "Environment variable not set for #{env}"
      return nil;
    end
  end

  return envs
end


end
