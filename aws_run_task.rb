#!/usr/bin/env ruby

require 'dotenv'
require_relative 'aws_utils'

Dotenv.load("#{Dir.home}/.env")

if ARGV.size != 2
  puts "USAGE: aws_run_task env-name command"
  exit 1
end

env_name = ARGV.shift
cmd_name = ARGV.shift

valid_envs = ENV['environments'].split(/ /)

unless valid_envs.include?(env_name) 
  puts "ERROR: invalid env-name '#{env_name}'"
  exit 1
end

task_revision = get_revision_number(env_name)
subnet = ENV['subnet']

cmd = "aws ecs run-task --cluster %env_name%-cluster --task-definition %env_name%-rake-tasks:#{task_revision} --count 1 " +
      "--launch-type FARGATE --network-configuration \"awsvpcConfiguration={subnets=[#{subnet}]}\" " +
      "--overrides '{\"containerOverrides\":[{\"name\": \"%env_name%-rake-tasks\", \"command\" : " +
      "[\"sh\", \"-c\", \"bundle exec rake \\\"%cmd_name%\\\"\"]}]}'"

cmd.gsub!(/%env_name%/, env_name)
cmd.gsub!(/%cmd_name%/, cmd_name)

puts "CMD: #{cmd}"
system(cmd)
