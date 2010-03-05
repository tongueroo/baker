# TODO: upload config files: dna.json and solo.rb

require 'net/ssh'
require 'pp'

class Baker
  def self.run(host)
    new(host)
  end
  
  def initialize(host, user = nil)
    log "start running chef recipes on #{host}"
    @debug = true
    @host = host
    @user = user
    Net::SSH.start(@host, @user) do |ssh|
      check
      upload_chef_configs(ssh)
      upload_recipes(ssh)
      run_chef(ssh)
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
    if !File.exist?("config/baker/dna.json") or !File.exist?("config/baker/solo.rb")
      raise "need to create a config/baker/dna.json and config/baker/solo.rb file, so it can be uploaded to the server that needs it"
    end
    bash_exec("tar czf chef-config.tgz config/baker")
    bash_exec("scp chef-config.tgz #{@host}:")
    ssh_exec(ssh, "rm -rf chef-config && tar -zxf chef-config.tgz && mv config/baker chef-config")
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
    ssh_exec(ssh, "mkdir -p #{@recipes_path}")
    ssh_exec(ssh, "tar -zxf recipes.tgz -C #{@recipes_path}")
    bash_exec("rm recipes.tgz")
  end
  
  def run_chef(ssh)
    log "running chef recipes on #{@host}..."
    chef_cmd = "chef-solo -c ~/chef-config/solo.rb -j ~/chef-config/dna.json"
    log "chef_cmd : #{chef_cmd}"
    ssh_exec(ssh, chef_cmd)
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

