#!/usr/bin/ruby

def usage
  puts "USAGE: #{$0} file_pattern [directory]"
  exit
end

directory = "."
usage if ARGV.size == 0

if ARGV.size > 0 then
  file_pattern = ARGV.shift
  if ARGV.size > 0 then
    directory = ARGV.shift
    usage if ARGV.size > 0
  end
end

(Dir["#{directory}/*"]+Dir["#{directory}/*/**/*"]).each do |fname|
  if /#{file_pattern}/.match(fname) then
    puts fname
  end
end
