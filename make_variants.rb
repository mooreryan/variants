#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

methods = File.join(File.expand_path('~'), 'lib', 'ruby', 'ryan.rb')
require_relative methods

Ryan.req *%w[parse_fasta]

# takes 0-based posns
def add_snp sequence, posn
  seq = sequence.dup
  base = seq[posn].upcase

  if base == "A"
    new_base = %w[C T G].sample
  elsif base == "C"
    new_base = %w[A T G].sample
  elsif base == "T"
    new_base = %w[A C G].sample
  elsif base == "G"
    new_base = %w[A C T].sample
  else
    abort "#{base} isn't A, C, T, or G"
  end

  seq[posn] = new_base
  [seq, base, new_base]
end

opts = Trollop.options do
  banner <<-EOS

  Add snps at certain positions.

  The posn file is name\tvar_name\tposn. The posns in this file are
  1-based coordinates.

  Options:
  EOS

  opt(:posn, 'Input file', type: :string)
  opt(:fasta, 'Input file', type: :string)
  opt(:outdir, 'Output directory', type: :string, default: '.')
end

posn = Ryan.check_file(opts[:posn], :posn)
fasta = Ryan.check_file(opts[:fasta], :fasta)
Ryan.try_mkdir(opts[:outdir])

# the posns in this hash are 0-based
posns = {}
File.open(opts[:posn]).each_line do |line|
  name, new_name, posn = line.chomp.split "\t"
  posn = posn.to_i
  if posns.has_key? name
    if posns[name].has_key? new_name
      posns[name][new_name] << (posn - 1)
    else
      posns[name][new_name] = [posn - 1]
    end
  else
    posns[name] = { new_name => [posn - 1] }
  end
end

FastaFile.open(opts[:fasta]).each_record do |head, seq|
  if posns.has_key? head
    snp_posns = posns[head]

    # these are 0-based posns
    snp_posns.each do |var, snps|
      old_base = new_base = ""

      new_seq = seq
      outf =
        File.join(opts[:outdir],
                  "#{fasta[:base]}.var_#{var}.fna")

      snps.each do |posn|
        new_seq, old_base, new_base = add_snp new_seq, posn
      end

      File.open(outf, "w") do |f|
        f.printf ">%s %s\n%s\n", head, var, new_seq
      end
    end
  end
end
