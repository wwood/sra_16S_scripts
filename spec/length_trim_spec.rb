require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


require 'rspec'
require 'pp'
require 'systemu'


script_under_test = File.basename(__FILE__).gsub(/_spec/,'')
path_to_script = File.join(File.dirname(__FILE__),'..','bin',script_under_test)


describe script_under_test do
  it 'should trim' do
    seqs = %w(>5 ATGCC >6 AAAAAA)

    status, stdout, stderr = systemu "#{path_to_script} -l 5", 'stdin' => seqs.join("\n")
    stderr.should be_nil
    status.exitstatus.should eq(0)
    stdout.should eq(%w(>5 ATGCC >6 AAAAA)+"\n")
  end
  it 'should trim and discard' do
    seqs = %w(>5 ATGCC >6 AAAAAA)

    status, stdout, stderr = systemu "#{path_to_script} -l 6", 'stdin' => seqs.join("\n")
    stderr.should be_nil
    status.exitstatus.should eq(0)
    stdout.should eq(%w(>6 AAAAAA).join("\n")+"\n")
  end
  it 'should accept a file argument' do
    seqs = %w(>5 ATGCC >6 AAAAAA)

    Tempfile.open('test') do |tempfile|
      tempfile.puts seqs.join("\n")

      status, stdout, stderr = systemu "#{path_to_script} -l 5 #{tempfile.path}"
      stderr.should be_nil
      status.exitstatus.should eq(0)
      stdout.should eq(%w(>5 ATGCC >6 AAAAA)+"\n")
    end
  end
end
