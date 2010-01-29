# TODO: upload config files: dna.json and solo.rb

require 'net/ssh'
require 'pp'

class RunRecipes
  def self.run(host)
    new(host)
  end
  
  def initialize(host, user = nil)
    log "start running chef recipes on #{host}"
    @host = host
    @user = user
    Net::SSH.start(@host, @user) do |ssh|
      check
      upload_chef_configs(ssh)
      upload_recipes(ssh)
      run(ssh)
    end
    log "done running chef recipes on #{host}"
  end
  
  def check
    if !File.exist?('cookbooks')
      raise "not in chef cookbooks project need to be in one"
    end
  end
  def upload_chef_configs(ssh)
    if !File.exist?("config/runchef/dna.json") or !File.exist?("config/runchef/solo.rb")
      raise "need to create a config/runchef/dna.json and config/runchef/solo.rb file, so it can be uploaded"
    end
    local_exec("tar czf chef-config.tgz config/runchef")
    local_exec("scp chef-config.tgz #{@host}:")
    ssh_exec(ssh, "rm -rf chef-config && tar -zxf chef-config.tgz && mv config/runchef chef-config")
    ssh_exec(ssh, "rm -f chef-config.tgz")
    local_exec("rm -f chef-config.tgz")
  end
  def upload_recipes(ssh)
    @file_cache_path = "/tmp/chef-solo"
    @recipes_path = "/tmp/chef-solo/recipes"
    # create
    local_exec("tar czf recipes.tgz .")
    # upload
    local_exec("scp recipes.tgz #{@host}:")
    # move
    log "removing current chef recipes : #{@recipes_path}"
    ssh_exec(ssh, "rm -rf #{@recipes_path}")
    log "extracting new chef recipes"
    ssh_exec(ssh, "mkdir #{@recipes_path}")
    ssh_exec(ssh, "tar -zxf recipes.tgz -C #{@recipes_path}")
  end
  
  def run(ssh)
    ssh_exec(ssh, "chef-solo -c ~/chef-config/solo.rb -j ~/chef-config/dna.json")
  end
  
private
  def log(msg)
    puts msg
  end
  def local_exec(command)
    log `#{command}`
  end
  def ssh_exec(ssh, command)

    unless ARGV.empty?
      log "Executing command: #{command}"
    end

    stdout = ""
    ssh.exec!(command) do |channel, stream, data|
      stdout << data if stream == :stdout
    end
    output = stdout

    # output = ssh.exec!(command)

    if output
      output = output.split("\n").join("\n  ")
      log "  ssh output: #{output}"
    end

    output
  end
end

