#!/usr/bin/env ruby

require 'crb-blast'
require 'round-robin'
require 'record'
require 'threach'
require 'rgl/adjacency'
require 'rgl/bidirectional'

class Node 
  attr_accessor :name, :annotation, :bitscore

  def initialize(name, annotation, bitscore)
    @name = name
    @annotation = annotation
    @bitscore = bitscore
  end

  def to_s
    "#{@name} #{@annotation} #{@bitscore}"
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

  def initialize reference, list, threads, output
    @reference = reference
    @files = list
    @threads = threads
    @output = output
  end

  def run
    pairwise = []
    (@files+[@reference]).each_with_index do |file1, i|
      (@files+[@reference]).each_with_index do |file2, j|
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