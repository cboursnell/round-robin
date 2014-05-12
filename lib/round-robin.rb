#!/usr/bin/env ruby

require 'crb-blast'
require 'round-robin'
require 'threach'

class Node 
  attr_accessor :name, :agi, :bitscore

  def initialize(name, agi, bitscore)
    @name = name
    @agi = agi
    @bitscore = bitscore
    # TODO add a count
    # TODO add a original of agi thingy
  end

  def to_s
    "#{@name} #{@agi} #{@bitscore}"
  end

  def <=> other
    return 0 if @name==other.name
    return 1 if @name>other.name
    return -1 if @name<other.name
  end

  def == other
    if @name == other.name
      return true
    else
      return false
    end
  end
end

class Robin

  attr_accessor 

  def initialize reference, list, threads
    @reference = reference
    @files = list
    @threads = threads
  end

  def run
    pairwise = []
    @files << @reference
    @files.each_with_index do |file1, i|
      @files.each_with_index do |file2, j|
        if i != j
          pairwise << [file1, file2]
        end
      end
    end
    pairwise.threach(@threads) do |pair|
      print "#{File.basename(pair[0])} => #{File.basename(pair[1])}\n"
      output = "#{File.basename(pair[0])}_into_#{File.basename(pair[1])}"
      blaster = CRB_Blast.new(pair[0], pair[1], output)
      dbs = blaster.makedb
      run = blaster.run_blast(1e-5, 1)
      load = blaster.load_outputs
      recips = blaster.find_reciprocals
      secondaries = blaster.find_secondaries
    end
  end

end