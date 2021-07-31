require 'bfs'
require 'thor'

module BFS
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc 'watch', 'Monitor a directory for new BFS .xml files to process.'
    method_option :directory, desc: 'The directory to watch for new files', aliases: '-d', default: BFS::DEFAULT_INPUT_DIR
    method_option :interval, desc: 'Seconds to sleep between scanning for new files', aliases: '-i', default: 120, type: :numeric
    def watch
      BFS.watch!(options[:directory], interval: options[:interval])
    end

    desc 'process FILEPATH', 'Process the specific BFS file given by FILEPATH'
    def process(filepath)
      BFS.process!(filepath)
    end

    desc 'clear', 'Deletes existing processed and error files'
    def clear
      BFS.clear!
    end

    desc 'seed', 'Seeds the default data directory with fixture files'
    def seed
      BFS.seed!
    end
  end
end
