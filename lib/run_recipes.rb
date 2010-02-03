# TODO: upload config files: dna.json and solo.rb

require 'net/ssh'
require 'pp'

class RunRecipes
  def self.run(host)
    new(host)
  end
  
  def initialize(host, user = nil)
    log "start running chef recipes on #{host}"
    @debug = false
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
    log "uploading chef configs to #{@host}..."
    if !File.exist?("config/run_recipes/dna.json") or !File.exist?("config/run_recipes/solo.rb")
      raise "need to create a config/run_recipes/dna.json and config/run_recipes/solo.rb file, so it can be uploaded to the server that needs it"
    end
    bash_exec("tar czf chef-config.tgz config/run_recipes")
    bash_exec("scp chef-config.tgz #{@host}:")
    ssh_exec(ssh, "rm -rf chef-config && tar -zxf chef-config.tgz && mv config/run_recipes chef-config")
    ssh_exec(ssh, "rm -f chef-config.tgz")
    bash_exec("rm -f chef-config.tgz")
  end
  def upload_recipes(ssh)
    log "uploading chef recipes to #{@host}..."
    @file_cache_path = "/tmp/chef-solo"
    @recipes_path = "/tmp/chef-solo/recipes"
    # create
    bash_exec("tar czf recipes.tgz .")
    # upload
    bash_exec("scp recipes.tgz #{@host}:")
    # move
    ssh_exec(ssh, "rm -rf #{@recipes_path}")
    ssh_exec(ssh, "mkdir #{@recipes_path}")
    ssh_exec(ssh, "tar -zxf recipes.tgz -C #{@recipes_path}")
    bash_exec("rm recipes.tgz")
  end
  
  def run(ssh)
    log "running chef recipes on #{@host}..."
    ssh_exec(ssh, "chef-solo -c ~/chef-config/solo.rb -j ~/chef-config/dna.json")
  end
  
private
  def log(msg)
    puts msg
  end
  def debug(msg)
    puts msg if @debug
  end
  def bash_exec(command)
    `#{command}`
  end
  def ssh_exec(ssh, command)

    unless ARGV.empty?
      debug "Executing command: #{command}"
    end

    stdout = ""
    ssh.exec!(command) do |channel, stream, data|
      stdout << data if stream == :stdout
    end
    output = stdout

    if output and @debug
      output = output.split("\n").join("\n  ")
      debug "  ssh output: #{output}"
    end

    output
  end
end

