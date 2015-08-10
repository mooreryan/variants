#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

methods = File.join(File.expand_path("~"), "lib", "ruby", "ryan.rb")
require_relative methods

Ryan.req *%w[]

opts = Trollop.options do
  banner <<-EOS

  Infile has contig\tnum_variants. The length of the contig comes from
  the spades style contig headers.

  Options:
  EOS

  opt(:infile, "Input file", type: :string)
end

infile = Ryan.check_file(opts[:infile], :infile)

File.open(opts[:infile]).each_line do |line|
  unless line.start_with? "contig"
    contig, num_vars = line.chomp.split "\t"

    len = contig.match(/_length_([0-9]+)_/)
    abort "cant find len of |#{contig}|" if len.nil?

    len = len[1].to_f

    puts [contig, num_vars, num_vars.to_i / len].join "\t"
  end
end
