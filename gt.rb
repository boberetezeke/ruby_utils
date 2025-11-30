#!/usr/bin/env ruby

require 'yaml'

def process(argv)
  if argv.size == 0
    puts "gt command [args]"
    puts 
    puts "  command"
    puts "    cd branch       --> git checkout branch"
    puts "    cda num branch  --> add base branch"
    puts "    cdn branch      --> git checkout -b branch"
    puts "    cdl             --> list last 10 uniq checkout branches"
    puts "    fch             --> git --fetch"
    puts "    pll             --> git pull origin [current_branch]"
    puts "    psh             --> git push origin [current_branch]"
    puts "    fpsh            --> git push -f origin [current_branch]"
    puts "    repo            --> display current repo"
    puts "    rmb             --> git branch -D branch"
    puts "    undo            --> git reset --soft HEAD~1"

    return 1
  end

  command = argv.shift
  unless %w[cd cda cdn cdl fch pll psh fpsh repo rmb undo].include?(command)
    puts "ERROR: invalid command '#{command}'"
    return 1
  end

  return self.send(command, argv)
end

def run_command(str)
  puts "RUNNING: #{str}"
  ret = system(str)
  puts "ERROR: running command #{str}" unless ret
  return ret
end

def cd(args)
  unless args.size == 1
    puts "ERROR: requires branch argument"
    return 1
  end

  branch = args.first
  data = read_git_data

  checkouts = data[:data][:checkouts][get_current_git_repo] || []
  index,error = branch_name_to_index(checkouts, branch, allow_unknown_branches: true)
  if error
    puts "ERROR: #{error}"
    return 1
  end
  if index
    branch = checkouts[index][:branch]
  end

#  if m = /^@(\d+)$/.match(branch)
#    item_num = m[1].to_i
#    if item_num <= checkouts.size
#      branch = checkouts[item_num - 1][:branch]
#    else
#      puts "ERROR: item number #{item_num} is not in cd history"
#      return 1
#    end
#  elsif branch == '@'
#    if checkouts.size > 1
#      branch = checkouts[1][:branch]
#    else
#      puts "ERROR: need at least two items in history to use #"
#      return 1
#    end
#  end

  if run_command("git checkout #{branch}")
    add_to_branch_history(branch)
  end

  return 0
end

def cda(args)
  unless args.size == 2
    if args.size == 1
      puts "ERROR: requires branch argument"
      return 1
    else
      puts "ERROR: requires num argument"
      return 1
    end
  end
  num = args[0].to_i
  branch = args[1]

  update_branch_history(num, branch)

  return 0
end

def cdn(args)
  unless args.size == 1
    puts "ERROR: requires branch argument"
    return 1
  end
  branch = args.first

  current_branch = get_current_branch
  if run_command("git checkout -b #{branch}")
    add_to_branch_history(branch, base_branch: current_branch)
  end

  return 0
end

def cdl(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  data = read_git_data
  (data[:data][:checkouts][get_current_git_repo] || [])[0..9].each_with_index do |checkout, index|
    puts(sprintf(
           "%2d   %-50s %-50s %-20s",
           index + 1,
           checkout[:branch],
           checkout[:base_branch],
           checkout[:time].strftime('%Y-%m-%d %H:%M'))
    )
  end
  puts
  puts "repo directory: #{get_current_git_repo}"

  return 0
end

def fch(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  run_command("git fetch --all")

  return 0
end

def psh(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  current_branch = get_current_branch
  unless current_branch
    puts "unable to get current branch" 
    return 1
  end

  run_command("git push origin #{current_branch}")

  return 0
end

def fpsh(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  current_branch = get_current_branch
  unless current_branch
    puts "unable to get current branch" 
    return 1
  end

  run_command("git push -f origin #{current_branch}")

  return 0
end

def pll(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  current_branch = get_current_branch
  unless current_branch
    puts "unable to get current branch"
    return 1
  end

  run_command("git pull origin #{current_branch}")

  return 0
end

def repo(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  puts "repo directory: #{get_current_git_repo}"
  return 0
end

def rmb(args)
  unless args.size == 1
    puts "ERROR: requires branch argument"
    return 1
  end
  branch = args.first

  data, cur_checkouts = load_git_data
  index,error = branch_name_to_index(cur_checkouts, branch)
  if error
    puts "ERROR: #{error}"
    return 1
  end
  branch = cur_checkouts[index][:branch]

  if run_command("git branch -D #{branch}")
    remove_from_branch_history(branch)
    return 0
  end

  return 1
end

def undo(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  run_command("git reset --soft HEAD~1")
end

# --------------------- utility functions ---------------------


def get_current_git_repo
  dir = Dir.pwd
  while true
    return dir if File.directory?(File.join(dir, '.git'))
    return nil unless dir.include?('/')

    dir = dir.split('/')[0..-2].join('/')
  end
end

def get_current_branch
  status = `git status`
  first_line = status.split(/\n/).first
  m = /On branch (.*)/.match(first_line)
  m[1] 
end

MAX_CHECKOUTS = 100

def update_branch_history(num, base_branch)
  data, cur_checkouts = load_git_data
  if num >= data[:data][:checkouts][get_current_git_repo].size
    return false
  else
    branch_info = data[:data][:checkouts][get_current_git_repo][num-1]
    branch_info[:base_branch] = base_branch
    data[:data][:checkouts][get_current_git_repo][num-1] = branch_info
  end

  puts data[:data][:checkouts][get_current_git_repo] 
end

def add_to_branch_history(branch, base_branch: nil)
  data, cur_checkouts = load_git_data
  # puts "cur_checkouts = #{cur_checkouts}"
  # puts "data[:data] = #{data[:data]}"
  # puts "data[:data][:checkouts] = #{data[:data][:checkouts]}"

  branch_info = find_branch(cur_checkouts, branch)
  base_branch ||= branch_info[:base_branch] if branch_info
  new_branch_info = { branch: branch, time: Time.now }
  new_branch_info[:base_branch] = base_branch if base_branch

  data[:data][:checkouts][get_current_git_repo] = [new_branch_info] +  without_branch(cur_checkouts, branch)[0..(MAX_CHECKOUTS - 2)]
  save_git_data(data)
end

def find_branch(cur_checkouts, branch)
  cur_checkouts.find{ |checkout| checkout[:branch] == branch }
end

def without_branch(cur_checkouts, branch)
  cur_checkouts.reject{|checkout_info| checkout_info[:branch] == branch}
end

def remove_from_branch_history(branch)
  data, cur_checkouts = load_git_data
  data[:data][:checkouts][get_current_git_repo] = cur_checkouts.reject { |checkout| checkout[:branch] == branch }
  save_git_data(data)
end

def branch_name_to_index(checkouts, branch_name, allow_unknown_branches: false)
  if m = /^@(\d+)$/.match(branch_name)
    item_num = m[1].to_i
    if item_num <= checkouts.size
      return [item_num - 1, nil]
    else
      return [nil, "item number #{item_num} is not in cd history"]
    end
  elsif branch_name == '@'
    if checkouts.size > 1
      return [1, nil]
    else
      return [nil, "need at least two items in history to use #"]
    end
  else 
    index = checkouts.index{ |checkout| checkout[:branch] == branch_name }
    if index
      return [index, nil]
    else
      if allow_unknown_branches
        return [nil, nil]
      else
        return [nil, "branch with name #{branch_name} not found"]
      end
    end
  end
end

def git_data_filename
  "/Users/stevetuckner/.gt.yml"
end

CURRENT_VERSION = 1

def empty_data
  {
    version: CURRENT_VERSION,
    data: {
      checkouts: {}
    }
  }
end

def load_git_data
  data = read_git_data
  # if data[:data][:checkouts].is_a?(Array)
  #  cur_checkouts = data[:data][:checkouts] || []
  #  cur_checkouts = cur_checkouts.reject { |checkout| checkout[:branch] == branch }
  #   data[:data][:checkouts] = { get_current_git_repo => [] }
  # else
    cur_checkouts = data[:data][:checkouts][get_current_git_repo] || []
  # end
  [data, cur_checkouts]
end

def read_git_data
  if File.exist?(git_data_filename)
    if RUBY_VERSION.to_f >= 3.1
      YAML.unsafe_load_file(git_data_filename)
    else
      YAML.load(File.open(git_data_filename))
    end
  else
    empty_data
  end
end

def save_git_data(data)
  File.open(git_data_filename, 'w') { |f| f.write(data.to_yaml)}
end

exit process(ARGV)
