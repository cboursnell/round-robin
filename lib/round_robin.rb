#!/usr/bin/env ruby

require 'crb-blast'
require 'round_robin'
require 'record'
require 'threach'
require 'set'
require 'rgl/adjacency'
require 'rgl/bidirectional'

class Node 
  attr_accessor :name, :annotation, :bitscore, :count

  def initialize(name, annotation, bitscore, count)
    @name = name
    @annotation = annotation
    @bitscore = bitscore
    @count = count
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

  attr_accessor :nodes, :contig_clusters, :contig_sets

  def initialize reference, list, threads, output
    reference = [reference] unless reference.is_a? Array
    list = [list] unless list.is_a? Array
    @reference = reference
    @files = list
    @threads = threads
    output = output[0..-2] if output[-1]=="/"
    @output = output
    # check all files exist
    @files.each do |file|
      abort "Can't find #{file}" if !File.exist?(file)
    end
    @reference.each do |ref|
      abort "Can't find #{ref}" if !File.exist?(ref)
    end
    @contig_clusters = Hash.new
    # hash: clusters[contig] = cluster_number
    @contig_sets = Hash.new
    # hash: contig_sets[set_number] = [list of contigs]
  end

  def run
    pairwise = []
    (@files+@reference).each_with_index do |file1, i|
      (@files+@reference).each_with_index do |file2, j|
        if i != j
          pairwise << [file1, file2]
        end
      end
    end

    @jobs = []

    pairwise.each do |pair|
      # print "#{File.basename(pair[0])} => #{File.basename(pair[1])}\n"
      output = "#{File.basename(pair[0])}_into_#{File.basename(pair[1])}"
      @jobs << CRB_Blast.new(pair[0], pair[1], "#{@output}/#{output}")
    end
    @jobs.threach(@threads) do |job|
      job.makedb
      job.run_blast(1e-5, 4)
    end
    
    @jobs.each do |job|
      job.load_outputs
      job.find_reciprocals
      job.find_secondaries
      job.write_output
      job.clear_memory
    end
  end

  def parse_outputs
    @nodes = Hash.new
    @graph = RGL::DirectedAdjacencyGraph.new
    # go through all the reciprocal_hits.txt files where the target is a ref
    @reference.each do |ref|
      target = File.basename(ref)
      @files.each do |file|
        query = File.basename(file)
        Dir.chdir("#{@output}/#{query}_into_#{target}") do |dir|
          File.open("reciprocal_hits.txt").each_line do |line|
            hit = Record.new(line, query, target)
            contig_name = hit.query
            if !@nodes.key?(contig_name)
              node = Node.new(contig_name, hit.target, hit.bitscore, 0)
              @nodes[contig_name] = node
            else
              if hit.bitscore > @nodes[contig_name].bitscore
                node = Node.new(contig_name, hit.target, hit.bitscore, 0)
                @nodes[contig_name] = node
              end
            end
          end
        end
      end
    end
    # now go through all the reciprocal_hits files for the queries
    @files.each_with_index do |file1, i|
      @files.each_with_index do |file2, j|
        if i != j
          query = File.basename(file1)
          target = File.basename(file2)
          Dir.chdir("#{@output}/#{query}_into_#{target}") do |dir|
            File.open("reciprocal_hits.txt").each_line do |line|
              hit = Record.new(line, query, target)
              contig_name1 = hit.query
              contig_name2 = hit.target
              node1 = Node.new(contig_name1, nil, nil, nil)
              node2 = Node.new(contig_name2, nil, nil, nil)
              if @nodes.key?(contig_name1)
                node1 = @nodes[contig_name1]
              else
                @nodes[contig_name1] = node1
              end
              if @nodes.key?(contig_name2)
                node2 = @nodes[contig_name2]
              else
                @nodes[contig_name2] = node2
              end
              @graph.add_edge(node1, node2)
            end
          end
        end
      end
    end
  end

  def output_edges name
    File.open("#{name}", "w") do |out|
      @nodes.each_pair do |name,node|
        if @graph.has_vertex?(node)
          degree = @graph.out_degree(node)
          # puts "name: #{name} node: #{node} degree: #{degree}"
          neighbours = @graph.adjacent_vertices(node)
          neighbours.each do |n|
            # puts "#{node.name}->#{n.name}"
            out.write "#{node.name}(#{node.annotation}|#{node.count}) -> "
            out.write "#{n.name}(#{n.annotation}|#{n.count})\n"
          end
        else
          # puts "#{name} agi:#{node.agi} bitscore:#{node.bitscore} is
          # not a vertex in graph g"
          # exit
        end
      end 
    end
  end

  def cascade cutoff
    @nodes.each_pair do |name, node|
      if node.annotation.nil?
        neighbours = @graph.adjacent_vertices(node)
        bitscore = -1
        annotation = nil
        count=0
        neighbours.each do |n|
          if n.bitscore != nil and n.bitscore > bitscore and n.count == cutoff
            annotation = n.annotation
            bitscore = n.bitscore
            count = n.count
          end
        end
        if annotation
          # puts "cascading annotation: #{node.name} -> #{annotation}"
          node.annotation = annotation
          node.bitscore = bitscore
          node.count = count + 1
        end
      end
    end
  end

  def get_annotation
    @annotation = Hash.new
    @nodes.each_pair do |name, node|
      (species, contig) = name.split(":")
      @annotation[species]=Hash.new if !@annotation.key?(species)
      unless node.annotation.nil?
        (reference_species, annotation) = node.annotation.split(":")
      end
      unless annotation=="" or annotation.nil?
        @annotation[species][contig] = {:species => reference_species,
                                        :annotation => annotation,
                                        :bitscore => node.bitscore,
                                        :count => node.count}
      end
    end
    @annotation
  end

  def get_cluster contig
    # contig name is in format "species:transcript"
    set = Set.new
    set << contig
    queue = []
    queue << contig
    while queue.size > 0
      front = queue.shift
      # puts "getting neighbours for \"#{front}\""
      if @nodes[front]
        @graph.adjacent_vertices(@nodes[front]).each do |n|
          if !set.include?(n.name)
            # puts "adding \"#{n.name}\" to the front of the queue"
            queue << n.name
            set << n.name
          end
        end
      end
    end
    set
  end

  def cluster

    cluster_number = 0
    @nodes.each_pair do |contig_name, node|
      if !@contig_clusters[contig_name]
        set = self.get_cluster contig_name
        @contig_sets[cluster_number] = []
        set.to_a.each do |l|
          @contig_clusters[l] = cluster_number
          @contig_sets[cluster_number] << l
        end
        cluster_number += 1
      end
    end
    cluster_number
  end

end
