#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'bio-faster'
require 'bio'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :log_level => 'info',
  :input_type => 'fasta',
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} -l <length> <fastq_file>

    Trim reads to the given length, discard them if they are not at least that given length. Output the trimmed reads as FASTA on stdout\n\n"

  opts.on("-l", "--length-cutoff LENGTH_IN_BASE_PAIRS", "Length to trim to [required]") do |arg|
    options[:length_cutoff] = arg
  end
  opts.on("--input-type TYPE", "Type of data being processed (fasta or fastq) [default: #{options[:input_type]}]") do |arg|
    raise "Unexpected --input-type #{arg}" unless %w(fasta fastq).include?(arg)
    options[:input_type] = arg
  end

  # logger options
  opts.separator "\nVerbosity:\n\n"
  opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {options[:log_level] = 'error'}
  opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
  opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| options[:log_level] = s}
end; o.parse!
if ARGV.length != 1 or options[:length_cutoff].nil?
  $stderr.puts o
  exit 1
end
# Setup logging
Bio::Log::CLI.logger(options[:logger]); Bio::Log::CLI.trace(options[:log_level]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

num_sufficient_length = 0
num_insufficient_length = 0

if options[:input_type] == 'fastq'
  fastq = Bio::Faster.new(ARGV[0])
  fastq.each_record(:quality => :raw) do |sequence_header, sequence, quality|
    if sequence.length >= options[:length_cutoff]
      puts '>'+sequence_header
      puts sequence[0...options[:length_cutoff]]
      num_sufficient_length += 1
    else
      num_insufficient_length += 1
    end
  end
elsif options[:input_type] == 'fasta'
  Bio::FlatFile.foreach(ARGF) do |seq|
    if seq.se.length >= options[:length_cutoff]
      puts ">#{seq.definition}"
      puts seq.seq[0...options[:length_cutoff]]
    end
  end
end
log.info "Trimmed #{num_sufficient_length} reads of sufficient length and discarded #{num_insufficient_length} of insufficient length"
