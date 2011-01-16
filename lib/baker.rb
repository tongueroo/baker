# TODO: upload config files: dna.json and solo.rb

require 'rubygems'
require 'net/ssh'
require 'net/sftp'
require 'pp'

require File.expand_path('../cli', __FILE__)

class Baker
  Version = "0.1.2"

  class NotCookbookProject < RuntimeError; end

  def self.setup(options)
    @baker = Baker.new(options)
    @baker.setup
  end
  def self.run(options)
    @baker = Baker.new(options)
    @baker.run
  end

  def initialize(options)
    @user   = nil
    @host   = options[:host] || raise("need to set host")
    @root   = Dir.pwd
    @logger = Logger.new(File.exist?("#{@root}/log") ? "#{@root}/log/baker.log" : "#{@root}/baker.log")
  end
  
  def setup
    log "*** setting up chef"
    Net::SFTP.start(@host, @user) do |sftp|
      sftp.upload!(
        File.expand_path("../../scripts/baker_setup.sh", __FILE__), 
        "/tmp/baker_setup.sh"
      )
    end
    Net::SSH.start(@host, @user) do |ssh|
      remote_cmd(ssh, "bash -ex /tmp/baker_setup.sh >> /var/log/baker.setup.log 2>&1;") # 
    end
    log "*** done setting up chef, check /var/log/baker.setup.log on #{@host} for possible errors."
  end
  
  def run
    validate_cookbook_project
    log "*** start running chef recipes on #{@host}"
    Net::SSH.start(@host, @user) do |ssh|
      upload_recipes(ssh)
      run_chef(ssh)
    end
    log "*** done running chef recipes, check /var/log/baker.chef.log on #{@host}"
  end

  def validate_cookbook_project
    if !File.exist?('cookbooks')
      raise NotCookbookProject.new("not in chef cookbooks project, @root is #{@root}")
    end
  end

  def upload_recipes(ssh)
    configs = %w{config/dna.json config/solo.rb}
    if configs.find{|x| !File.exist?(x) }
      raise "Need to create #{configs.join(', ')} files, it's required for chef to run."
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
    chef_cmd = "chef-solo -c /tmp/baker/recipes/config/solo.rb -j /tmp/baker/recipes/config/dna.json > /var/log/baker.chef.log 2>&1"
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

    # TODO: mess with this later so try to catch the stderr when chef-solo run fails
    # def remote_cmd(ssh, command)
    #   puts "remote cmd: #{command}"
    #   ssh.open_channel do |channel| 
    #     channel.exec(command) do |ch, success|
    #       unless success
    #         abort "FAILED: couldn't execute command (ssh.channel.exec failure) #{command}"
    #       end
    #       # stdout
    #       channel.on_data do |ch, data|  # stdout
    #         print data
    #       end
    #       # stderr
    #       channel.on_extended_data do |ch, type, data|
    #         next unless type == 1  # only handle stderr
    #         $stderr.print data
    #       end
    #       channel.on_request("exit-status") do |ch, data|
    #         exit_code = data.read_long
    #         if exit_code > 0
    #           puts "ERROR: exit code #{exit_code}"
    #         else
    #           puts "success"
    #         end
    #       end
    #       channel.on_request("exit-signal") do |ch, data|
    #         puts "SIGNAL: #{data.read_long}"
    #       end
    #     end
    #   end
    # end
    
end