# spec/bfs_spec.rb
require 'pathname'
require 'date'
require 'bfs'

describe BFS do
  let(:bfs_file) { './data/invoicing/pay/3540022930006532-1623116226819.xml' }
  let(:bfs_processed) { './data/processed/3540022930006532-1623116226819.txt' }
  let(:bfs_error) { './data/rejected/3540022930006532-1623116226819_errors.txt' }

  it 'starts from clean data directory' do
    BFS.clear!
    expect(Pathname.new(bfs_file)).to_not exist
  end

  it 'Adds test invoices to data/invoicing/pay' do
    BFS.seed!
    expect(Pathname.new(bfs_file)).to exist
  end

  it 'Processes an invoice and creates error files and BFS file' do
    BFS.seed!
    BFS.process! bfs_file
    expect(Pathname.new(bfs_processed)).to exist
    expect(Pathname.new(bfs_error)).to exist
  end

  it 'Removes test invoices from data directories' do
    BFS.clear!
    expect(Pathname.new(bfs_file)).to_not exist
  end

end
