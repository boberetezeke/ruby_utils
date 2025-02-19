require 'json'
def get_task_number(env_name)
  task_info = `aws ecs list-tasks --cluster #{env_name}-cluster --service-name #{env_name}-backend`
  task_num = JSON.parse(task_info)
  task_entry = task_num['taskArns'].first
  /#{env_name}-cluster\/(.*)/.match(task_entry).captures.first
end

def get_revision_number(env_name)
  `aws ecs describe-task-definition --task-definition #{env_name}-rake-tasks --query 'taskDefinition.revision' --output text`
end