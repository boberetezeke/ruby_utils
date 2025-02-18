if ARGV.size != 1
  puts "USAGE: aws_run_console env-name"
  exit 1
end

env_name = ARGV.shift

valid_envs = ['feature-1', 'feature-2', 'feature-3', 'feature-4', 'uat-review-1']

unless valid_envs.include?(env_name) 
  puts "ERROR: invalid env-name '#{env_name}'"
  exit 1
end

cmd = "aws ecs execute-command --region us-east-1 --cluster %env_name%-cluster --task 4a743658789846c29f72e5b00d41f497 --container %env_name%-backend --command \"/bin/sh\" --interactive"

cmd.gsub!(/%env_name%/, env_name)

puts "CMD: #{cmd}"
puts "RAILS CONSOLE CMD: ./.docker/rails-entrypoint.sh rails console"
puts "----------------"
system(cmd)
