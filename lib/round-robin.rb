#!/usr/bin/env ruby

require 'crb-blast'
require 'round-robin'
require 'record'
require 'threach'
require 'rgl/adjacency'
require 'rgl/bidirectional'

class Node 
  attr_accessor :name, :annotation, :bitscore
  # TODO add a count

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
    reference = [reference] unless reference.is_a? Array
    @reference = reference
    @files = list
    @threads = threads
    @output = output
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
    puts "making list of jobs"
    pairwise.each do |pair|
      # print "#{File.basename(pair[0])} => #{File.basename(pair[1])}\n"
      output = "#{File.basename(pair[0])}_into_#{File.basename(pair[1])}"
      @jobs << CRB_Blast.new(pair[0], pair[1], output:"#{@output}/#{output}")
    end
    puts "threach"
    @jobs.threach(@threads) do |job|
      job.makedb
      # puts "job: #{job.query_name}\t#{job.target_name}"
      job.run_blast(1e-5, 1)
    end
    
    puts "Done"
    @jobs.each do |job|
      # puts "job: #{job.query_name}\t#{job.target_name}"
      # puts "  loading"
      job.load_outputs
      # puts "  find1"
      job.find_reciprocals
      # puts "  find2"
      job.find_secondaries
      # puts "  writing"
      job.write_output
      job.clear_memory
    end
  end

  def parse_outputs
    @nodes = Hash.new
    @graph = RGL::DirectedAdjacencyGraph.new
    ref = File.basename(@reference)
    @jobs.each do |job|
      Dir.chdir(job.working_dir) do |dir|
        if File.exist?("reciprocal_hits.txt")
          puts "#{job.query_name}\t#{job.target_name}"
          File.open("reciprocal_hits.txt").each_line do |line|
            hit = Record.new(line, job.query_name, job.target_name)
            if ref =~ /#{job.target_name}/
              # puts "#{job.target_name}\t#{ref}"
              contig_name = hit.query
              if !@nodes.key?(contig_name)
                node = Node.new(contig_name, hit.target, hit.bitscore)
                @nodes[contig_name] = node
                # puts "#{node.name}\t#{node.annotation}"
              else
                puts "this shouldn't happen"
                if @nodes[contig_name].annotation.nil?
                  @nodes[contig_name].annotation = hit.target
                  @nodes[contig_name].bitscore = hit.bitscore
                end
              end
            else
              # puts "are you sure?"
            end
          end
        else
          puts "error: file not found in #{dir}"
        end
      end
    end
    # exit
    # second
    @jobs.each do |job|
      Dir.chdir(job.working_dir) do |dir|
        if File.exist?("reciprocal_hits.txt")
          puts "#{job.query_name}\t#{job.target_name}"
          File.open("reciprocal_hits.txt").each_line do |line|
            hit = Record.new(line, job.query_name, job.target_name)
            if ref =~ /#{job.target_name}/

            else
              # puts "branch nodes"
              contig_name1 = hit.query
              contig_name2 = hit.target
              node1 = Node.new(contig_name1, nil, nil)
              node2 = Node.new(contig_name2, nil, nil)
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
        else
          puts "error: file not found in #{dir}"
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
            out.write "#{node.name}(#{node.annotation}) -> #{n.name}(#{n.annotation})\n"
          end
        else
          # puts "#{name} agi:#{node.agi} bitscore:#{node.bitscore} is not a vertex in graph g"
          # exit
        end
      end 
    end
  end

  def cascade
    @nodes.each_pair do |name, node|
      if node.annotation.nil?
        neighbours = @graph.adjacent_vertices(node)
        # puts "#{name}\t#{neighbours.length}"
        if name =~ /cd:transcript_32/
          neighbours.each do |n|
            puts n
          end
        end
        bitscore = -1
        annotation = nil
        neighbours.each do |n|
          if n.bitscore != nil and n.bitscore > bitscore
            annotation = n.annotation
            bitscore = n.bitscore
          end
        end
        if annotation
          # puts "cascading annotation: #{node.name} -> #{annotation}"
          node.annotation = annotation
          node.bitscore = bitscore
        end
      end
    end
  end

  def get_annotation
    @annotation = Hash.new
    @nodes.each_pair do |name, node|
      (species, contig) = name.split(":")
      @annotation[species]=Hash.new if !@annotation.key?(species)
      annotation = node.annotation.split(":").last unless node.annotation.nil?
      unless annotation=="" or annotation.nil?
        @annotation[species][contig] = annotation 
      end
    end
    @annotation
  end

end