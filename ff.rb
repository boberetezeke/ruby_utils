#!/usr/bin/env ruby

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

def get_fnames(directory)
  fnames = []
  local_fnames = Dir["#{directory}/{*,.*}"]
  local_fnames.each do |local_fname|
    if (File.basename(local_fname) != '.' && File.basename(local_fname) != '..')
      if File.directory?(local_fname)
        fnames += get_fnames(local_fname)
      else
        fnames.push(local_fname)
      end
    end
  end

  fnames
end

get_fnames(directory).each do |fname|
  if /#{file_pattern}/.match(fname) then
    puts fname
  end
end
