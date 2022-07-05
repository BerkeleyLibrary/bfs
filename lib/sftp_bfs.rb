require 'net/ssh'
require 'net/sftp'
require_relative 'logging'
include Logging

module SftpBfs 

# Get an SFTP connection to BFS server
def self.sftp_bfs()
  retries = 0
  logger.info "trying to connect to BFS SFTP server"
  begin
    sftp = Net::SFTP.start(
      'ucmft.berkeley.edu',
      'cUCB100_library',
      { append_all_supported_algorithms: true }
    )

    logger.info 'connected'
  rescue StandardError => e
    sleep 10
    retry if (retries += 1) < 4
    logger.error "Could not connect to remote server #{e}. Tried to connect #{retries} time(s)"
    return
  end

  logger.info "Connected to BFS SFTP server"
  sftp
end


def self.sftp_file(file)
  sftp = sftp_bfs
  logger.info "Going to ftp #{file}"
  begin
    sftp.upload!(file,"2UCB/VOUCHER/#{File.basename(file)}")
  rescue StandardError => e
    logger.error "Failed to upload #{file} #{e}"
    return
  end
  logger.info "Successfully sent #{file}"
end


end
