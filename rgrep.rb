#!/usr/bin/ruby

def usage
  puts "USAGE: #{$0} pattern [directory [file_pattern]]"
  exit
end

directory = "."
file_pattern = ".*"
usage if ARGV.size == 0
pattern = ARGV.shift
if ARGV.size > 0 then
  directory = ARGV.shift
  if ARGV.size > 0 then
    file_pattern = ".*" + ARGV.shift + ".*"
    usage if ARGV.size > 0
  end
end

(Dir["#{directory}/*"]+Dir["#{directory}/*/**/*"]).each do |fname|
  if /#{file_pattern}/.match(fname) then
    unless File.directory?(fname)
      lines = File.readlines(fname)
      lines.each_with_index do |line, index|
        puts "#{fname}:#{index+1}::#{line}" if /#{pattern}/.match(line)
      end
    end
  end
end

