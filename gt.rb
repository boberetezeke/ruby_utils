#!/usr/bin/env ruby

require 'yaml'

def process(argv)
  if argv.size == 0
    puts "gt command [args]"
    puts 
    puts "  command"
    puts "    cd branch   --> git checkout branch"
    puts "    cdn branch  --> git checkout -b branch"
    puts "    cdl         --> list last 10 uniq checkout branches"
    puts "    fch         --> git --fetch"
    puts "    pll         --> git pull origin [current_branch]"
    puts "    psh         --> git push origin [current_branch]"
    puts "    repo        --> display current repo"
    puts "    rmb         --> git branch -D branch"
    puts "    undo        --> git reset --soft HEAD~1"

    return 1
  end

  command = argv.shift
  unless %w[cd cdn cdl fch pll psh repo rmb undo].include?(command)
    puts "ERROR: invalid command '#{command}'"
    return 1
  end

  return self.send(command, argv)
end

def run_command(str)
  puts "RUNNING: #{str}"
  system(str)
end

def cd(args)
  unless args.size == 1
    puts "ERROR: requires branch argument"
    return 1
  end

  branch = args.first
  data = read_git_data
  checkouts = data[:data][:checkouts][get_current_git_repo] || []
  if m = /^@(\d+)$/.match(branch)
    item_num = m[1].to_i
    if item_num <= checkouts.size
      branch = checkouts[item_num - 1][:branch]
    else
      puts "ERROR: item number #{item_num} is not in cd history"
      return 1
    end
  elsif branch == '@'
    if checkouts.size > 1
      branch = checkouts[1][:branch]
    else
      puts "ERROR: need at least two items in history to use #"
      return 1
    end
  end

  if run_command("git checkout #{branch}")
    add_to_branch_history(branch)
  end

  return 0
end

def cdn(args)
  unless args.size == 1
    puts "ERROR: requires branch argument"
    return 1
  end
  branch = args.first

  if run_command("git checkout -b #{branch}")
    add_to_branch_history(branch)
  end
end

def cdl(args)
  unless args.size == 0
    puts "ERROR: no arguments required"
    return 1
  end

  data = read_git_data
  (data[:data][:checkouts][get_current_git_repo] || [])[0..9].each_with_index do |checkout, index|
    puts(sprintf(
           "%2d   %-50s  %-20s",
           index + 1,
           checkout[:branch],
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

  if run_command("git branch -D #{branch}")
    remove_from_branch_history(branch)
  end
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

def add_to_branch_history(branch)
  data, cur_checkouts = load_git_data(branch)
  # puts "cur_checkouts = #{cur_checkouts}"
  # puts "data[:data] = #{data[:data]}"
  # puts "data[:data][:checkouts] = #{data[:data][:checkouts]}"
  data[:data][:checkouts][get_current_git_repo] = [{ branch: branch, time: Time.now }] +  without_branch(cur_checkouts, branch)[0..(MAX_CHECKOUTS - 2)]
  save_git_data(data)
end

def without_branch(cur_checkouts, branch)
  cur_checkouts.reject{|checkout_info| checkout_info[:branch] == branch}
end

def remove_from_branch_history(branch)
  data, cur_checkouts = load_git_data(branch)
  data[:data][:checkouts][get_current_git_repo] = cur_checkouts
  save_git_data(data)
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

def load_git_data(branch)
  data = read_git_data
  if data[:data][:checkouts].is_a?(Array)
    cur_checkouts = data[:data][:checkouts] || []
    cur_checkouts = cur_checkouts.reject { |checkout| checkout[:branch] == branch }
    data[:data][:checkouts] = { get_current_git_repo => [] }
  else
    cur_checkouts = data[:data][:checkouts][get_current_git_repo] || []
  end
  [data, cur_checkouts]
end

def read_git_data
  if File.exist?(git_data_filename)
    YAML.load(File.open(git_data_filename))
  else
    empty_data
  end
end

def save_git_data(data)
  File.open(git_data_filename, 'w') { |f| f.write(data.to_yaml)}
end

exit process(ARGV)
