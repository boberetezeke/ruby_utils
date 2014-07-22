#!/usr/bin/env ruby

require 'optparse'
require "fileutils"
require "yaml"

class LineMap
  def initialize(filename)
    @lines = {}
    @output_filename = ".#{filename}"
    @feature_line_num = 1
  end

  def lookup(filename, line_num)
    dictionary = {}
    begin
      File.open(@output_filename) { |f| dictionary = YAML::load(f) }
    rescue Exception
      return nil
    end
    return dictionary[line_num]
  end

  def write
    FileUtils::mkdir_p(File.dirname(@output_filename))
    File.open(@output_filename, 'w') {|f| f.write @lines.to_yaml }
  end

  def add_line(line)
    if step_line(cleaned(line))
      @lines[@feature_line_num-1] = { filename: @filename, line_num: @line_num }
    end 
    @feature_line_num += 1
  end

  def step_line(line)
    m = /# ([\w\/\.]+):(\d+)$/.match(line)
    if m then
      @filename = m[1]
      @line_num = m[2].to_i
    end
    return m
  end

  def cleaned(s)
    s.gsub(/\e\[\d+\m/, "")
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: pickler.rb [--lookup filename line_num] | [--capture filename]"

  opts.on("-c", "--[no-]capture", "capture cucumber output") do |v|
    options[:capture] = v
  end

  opts.on("-l", "--[no-]lookup", "lookup line numbers file and line number") do |v|
    options[:lookup] = v
  end
end.parse!

if options[:lookup] && options[:capture]
  puts "ERROR: --lookup and --capture options are mutually exclusive"
  exit 1
end

if !options[:lookup] && !options[:capture]
  puts "ERROR: --lookup or --capture options are required"
  exit 1
end

if options[:lookup]
  if ARGV.size != 2
    puts "ERROR: filename and line number required for lookup"
    exit 1
  end
  filename =  ARGV.shift
  line_num = ARGV.shift.to_i
end

if options[:capture]
  if ARGV.size != 1
    puts "ERROR: filename required for capture"
    exit 1
  end
  filename = ARGV.shift
end

line_map = LineMap.new(filename)
if options[:capture]
  while s=gets
    puts s
    line_map.add_line(s)
  end
  line_map.write
else
  source = line_map.lookup(filename, line_num)
  if source then
    puts "for #{filename}:#{line_num} source at #{source[:filename]}:#{source[:line_num]}"
  else
    puts "ERROR: for #{filename}:#{line_num} source not found"
    exit 1
  end
end

exit 0
