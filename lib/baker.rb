# TODO: upload config files: dna.json and solo.rb

require 'rubygems'
require 'net/ssh'
require 'pp'

class NotCookbookProject < RuntimeError; end

class Baker
  def self.run(options)
    @baker = Baker.new(options)
    @baker.run
  end
  
  def initialize(options)
    @host = options[:host] || raise("need to set host")
    @user = options[:user]
    @root = options[:root] || Dir.pwd
    set_logger
  end
  
  def set_logger
    @logger = if File.exist?(@root+"/log")
      Logger.new(@root+"/log/baker.log")
    else
      Logger.new(@root+"/baker.log")
    end
  end
  
  def run
    validate_cookbook_project
    log "*** start running chef recipes on #{@host}"
    Net::SSH.start(@host, @user) do |ssh|
      upload_recipes(ssh)
      run_chef(ssh)
    end
    log "*** done running chef recipes on #{@host}"
  end
  
  def validate_cookbook_project
    if !File.exist?('cookbooks')
      raise NotCookbookProject.new("not in chef cookbooks project, @root is #{@root}")
    end
  end

  def upload_recipes(ssh)
    if !File.exist?("config/dna.json") or !File.exist?("config/solo.rb")
      raise "need to create a config/dna.json and config/solo.rb file, so it can be uploaded to the server that needs it"
    end

    log "*** uploading chef recipes to #{@host}..."
    @recipes_path = "/tmp/baker/recipes"
    @tarball = "#{File.dirname(@recipes_path)}/recipes.tgz"
    # create tarball
    local_cmd("tar czf /tmp/recipes.tgz config cookbooks")
    # upload to /tmp/baker/recipes
    remote_cmd(ssh, "if [ -d '#{@recipes_path}' ] ; then rm -rf #{@recipes_path}; fi") # cleanup from before
    remote_cmd(ssh, "if [ ! -d '#{@recipes_path}' ] ; then mkdir -p #{@recipes_path}; fi")
    local_cmd("scp /tmp/recipes.tgz #{@host}:#{@tarball}")
    # not using -C flag changes /root folder owner!!! and screws up ssh access
    remote_cmd(ssh, "tar -zxf #{@tarball} -C #{@recipes_path}")
    # # cleanup both remote and local
    remote_cmd(ssh, "rm -f /tmp/baker/recipes.tgz")
    local_cmd("rm -f /tmp/recipes.tgz")
  end
  
  def run_chef(ssh)
    log "*** running chef recipes on #{@host}..."
    chef_cmd = "chef-solo -c /tmp/baker/recipes/config/solo.rb -j /tmp/baker/recipes/config/dna.json > /var/log/baker-chef-server.log 2>&1"
    log "CHEF_CMD : #{chef_cmd}"
    remote_cmd(ssh, chef_cmd)
  end
  
private
  def log(msg)
    puts(msg)
    @logger.info(msg)
  end
  
  def local_cmd(command)
    puts "local cmd: #{command}"
    `#{command}`
  end
  def remote_cmd(ssh, command)
    puts "remote cmd: #{command}"
    stdout = ""
    ssh.exec!(command) do |channel, stream, data|
      stdout << data if stream == :stdout
    end
    output = stdout

    if output
      output = output.split("\n").join("\n  ")
      puts "remote output: #{output}"
    end

    output
  end
end

