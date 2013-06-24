#!/usr/bin/env ruby

require 'optparse'
require 'bio-logger'
require 'open3'
require 'tempfile'

if __FILE__ == $0 #needs to be removed if this script is distributed as part of a rubygem
  SCRIPT_NAME = File.basename(__FILE__); LOG_NAME = SCRIPT_NAME.gsub('.rb','')

  # Parse command line options into the options hash
  options = {
    :logger => 'stderr',
  }
  o = OptionParser.new do |opts|
    opts.banner = "
      Usage: #{SCRIPT_NAME} --ssu-database <FASTA_PATH> <SRA_file>

      Takes an SRA run file, and determines whether the data contained within the file is 16S amplicon data or not.\n\n"

      opts.on("--ssu-database FASTA_PATH", "path to already makeblastdb'd fasta file of the 16S sequences [required]") do |arg|
        options[:ssu_database] = arg
      end

    # logger options
    opts.on("-q", "--quiet", "Run quietly, set logging to ERROR level [default INFO]") {Bio::Log::CLI.trace('error')}
    opts.on("--logger filename",String,"Log to file [default #{options[:logger]}]") { |name| options[:logger] = name}
    opts.on("--trace options",String,"Set log level [default INFO]. e.g. '--trace debug' to set logging level to DEBUG"){|s| Bio::Log::CLI.trace(s)}
  end
  o.parse!
  if ARGV.length != 1
    $stderr.puts o
    exit 1
  end
  # Setup logging. bio-logger defaults to STDERR not STDOUT, I disagree
  Bio::Log::CLI.logger(options[:logger]); log = Bio::Log::LoggerPlus.new(LOG_NAME); Bio::Log::CLI.configure(LOG_NAME)

  sra_lite = ARGV[0]
  log.info "Analysing #{sra_lite}"

  is_16s = false

  # convert it to a fastq file, taking the first 10 sequences, convert to fasta format, save as 10seqs.fa
  Tempfile.open('sra_head') do |fasta_file|
    fasta_name = fasta_file.path

    command = 'fastq-dump -M 200 -Z \''+ #dump the lite sra file to fastq format. Take sequences 100-140
     sra_lite+
     '\' |head -n 280 |tail -n 120'+#take sequences 30 to 70 (fastq 30*4=120 to 70*4=280)
     ' |awk \'{print ">" substr($0,2);getline;print;getline;getline}\' >'+fasta_name+ #convert to fasta format
     ' && blastn -query '+fasta_name+' -outfmt 6 -max_target_seqs 1 -db '+ #blast
     options[:ssu_database] # against a reduced set of 16S sequences from greengenes
    log.debug "Running command to extract the first 10 sequences: #{command}"
    Open3.popen3(command) do |stdin, stdout, stderr|
      err = stderr.readlines
      if err.length != 0 and (err.length != 2 or err[1].split(' ')[0] != 'Written')
        log.error "Error running command: #{err.join("\n")}"
      end

      is_16s = true if stdout.readlines.length > 0
    end
    puts [sra_lite, is_16s].join("\t")
  end

end #end if running as a script
