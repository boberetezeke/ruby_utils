if ARGV.size != 3
  puts "USAGE: aws_run_task env-name task-num command"
  exit 1
end

env_name = ARGV.shift
task_num = ARGV.shift
cmd = ARGV.shift

valid_envs = ['feature-1', 'feature-2', 'feature-3', 'feature-4', 'uat-review-1']

unless valid_envs.include?(env_name) 
  puts "ERROR: invalid env-name '#{env_name}'"
  exit 1
end

unless /^\d+$/.match(task_num)
  puts "ERROR: invalid task number: `#{task_num}'"
  exit 1
end

cmd = "aws ecs run-task --cluster %env_name%-cluster --task-definition %env_name%-rake-tasks:%task_num% --count 1 --launch-type FARGATE --network-configuration \"awsvpcConfiguration={subnets=[subnet-0b3662ef34308c1fe]}\" --overrides '{\"containerOverrides\":[{\"name\": \"%env_name%-rake-tasks\", \"command\" : [\"sh\", \"-c\", \"bundle exec rake \\\"%cmd%\\\"\"]}]}'"

cmd.gsub!(/%env_name%/, env_name)
cmd.gsub!(/%task_num%/, task_num)
cmd.gsub!(/%cmd%/, cmd)

puts "CMD: #{cmd}"

