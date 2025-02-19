#!/usr/bin/env ruby

require 'dotenv'
require_relative 'aws_utils'

Dotenv.load("#{Dir.home}/.env")

if ARGV.size != 1
  puts "USAGE: aws_run_console env-name"
  exit 1
end

env_name = ARGV.shift

valid_envs = ENV['environments'].split(/ /)

unless valid_envs.include?(env_name) 
  puts "ERROR: invalid env-name '#{env_name}'"
  exit 1
end

task_num = get_task_number(env_name)

cmd = "aws ecs execute-command --region us-east-1 --cluster %env_name%-cluster --task #{task_num} --container %env_name%-backend --command \"/bin/sh\" --interactive"

cmd.gsub!(/%env_name%/, env_name)

puts "CMD: #{cmd}"
puts "RAILS CONSOLE CMD: ./.docker/rails-entrypoint.sh rails console"
puts "----------------"
system(cmd)
