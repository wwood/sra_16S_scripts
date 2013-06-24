#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'

require 'reachable'
require 'bio-sra'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :log_level => 'info',
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} -d <SRAmetadb.sqlite>

    Print a list of accessions to be downloaded from the SRA\n\n"

  opts.on("-d", "--db PATH", "Path the the SRAmetadb.sqlite file/database [required]") do |f|
    options[:db_path] = f
  end

  # logger options
  opts.separator "\nVerbosity:\n\n"
  opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {options[:log_level] = 'error'}
  opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
  opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| options[:log_level] = s}
end; o.parse!
if ARGV.length != 0 or options[:db_path].nil?
  $stderr.puts o
  exit 1
end
# Setup logging
Bio::Log::CLI.logger(options[:logger]); Bio::Log::CLI.trace(options[:log_level]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

include Bio::SRA::Tables

# Connect
Bio::SRA::Connection.connect(options[:db_path])
log.info "Connected to SRAdb database #{options[:db_path]}"

list = SRA.where(
  :library_strategy => 'AMPLICON').where(
  :platform => 'LS454').select(
  'distinct(run_accession)').all.collect{|s| s.run_accession}

log.info "Printing the #{list.length} suitable SRA runs"

puts list.join("\n")
