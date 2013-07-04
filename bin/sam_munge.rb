#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'csv'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require 'sra_16S_scripts'

require 'bio-cigar'

SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

# Parse command line options into the options hash
options = {
  :logger => 'stderr',
  :log_level => 'info',
}
o = OptionParser.new do |opts|
  opts.banner = "
    Usage: #{SCRIPT_NAME} <arguments>

    Description of what this program does...\n\n"

  opts.on("-e", "--eg ARG", "description [default: #{options[:eg]}]") do |arg|
    options[:example] = arg
  end

  # logger options
  opts.separator "\nVerbosity:\n\n"
  opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {options[:log_level] = 'error'}
  opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
  opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| options[:log_level] = s}
end; o.parse!
if ARGV.length != 0
  $stderr.puts o
  exit 1
end
# Setup logging
Bio::Log::CLI.logger(options[:logger]); Bio::Log::CLI.trace(options[:log_level]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

# Read in the taxonomy file into a hash
log.info "Reading taxonomy file.."
taxonomies = {}
CSV.foreach(options[:taxonomy_file], :col_sep => "\t", :header => true) do |row|
  raise "Unexpected taxonomy file line: #{row.inspect}" unless row.length == 2
  raise "Duplicate taxon id: #{row[0]}" if taxonomy.key?(row[0])
  taxonomies[row[0]] = row[1]
end
log.info "Finished reading #{taxonomies.length} taxonomy entries"

log.info "Reading the reference sequences file.."
reference_sequences = {}
Bio::FlatFile.foreach(options[:reference_fasta]) do |seq|
  reference_sequences[seq.definition.split(/\s/)[0]] = seq.seq
end
log.info "Finished reading #{reference_sequences.length} sequences"


# Go through the sam file
#Foreach alignment from the sam file
num_chimeras = 0
num_alns = 0
log.debug "Reading through sam file.."
Bio::SamIterator.new(File.open options[:sam_file]).each_alignment do |alns|
  # ignore if there is 2 or more from the same pyrotag, as these are likely chimeric pyrotags
  if alns.length > 1
    num_chimeras += 1

  # print out the read name, hit ID, percent identity, taxonomy
  else
    p aln
    alns = aln
    cigar = Bio::Cigar.new aln.cigar
    ref = reference_sequences[aln.rname]
    raise "Could not find reference sequence for #{aln.rname}!" if ref.nil?
    identity = cigar.percent_identity(ref, aln.seq)
    tax = taxonomies[aln.rname]
    raise "Could not find taxonomy for #{aln.rname}" if tax.nil?
    puts [
      aln.qname,
      aln.rname,
      percent_identity,
      tax
    ].join "\t"
    num_alns += 1
  end
end
log.info "Finished writing #{num_alns} alignments, ignored #{num_chimeras} chimeras"
