module Bio
  class SamIterator
    class SamAlignment
      attr_accessor :qname, :flag, :rname,:pos,:mapq,:cigar, :mrnm, :mpos, :isize, :seq, :qual

      def initialize(sam)
        s = sam.split("\t")
        self.qname = s[0]
        self.flag  = s[1].to_i
        self.rname = s[2]
        self.pos   = s[3].to_i
        self.mapq  = s[4].to_i
        self.cigar = s[5]
        self.mrnm  = s[6]
        self.mpos  = s[7].to_i
        self.isize = s[8].to_i
        self.seq   = s[9]
        self.qual =  s[10]
      end

  # Work out the percent identity given of the query sequence
    # against the reference sequence, using the CIGAR string as
      # the alignment
        def percent_identity(reference_sequence)
            return Bio::Cigar.new(self.cigar).percent_identity(
                  reference_sequence[self.pos-1...reference_sequence.length],
                        self.seq
                            )
                              end

    end

    class AlignmentSet < Array
    end

    def initialize(io)
      @io = io
    end

    def each_alignment_set(&block)
      last_alignment_name = nil
      current_set = nil
      @io.each_line do |line|
        aln = SamAlignment.new(line.chomp)
        if last_alignment_name != aln.qname
          unless current_set.nil?
            yield current_set
          end
          current_set = AlignmentSet.new
        end
        current_set.push aln
        last_alignment_name = aln.qname
      end
      # yield the last set, if there is one
      yield current_set unless current_set.nil?
      nil
    end

    alias_method :each, :each_alignment_set
    include Enumerable
  end
end

