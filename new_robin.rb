#!/usr/bin/env ruby

require 'crb-blast'

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

  def initialize
    @files = []
  end

  def add_files 
  end

  def run
    @files.threach(threads) do
      
    end
  end

end