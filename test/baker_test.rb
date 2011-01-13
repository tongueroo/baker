require 'rubygems'
require 'test/spec'
require 'mocha'
require File.dirname(__FILE__)+"/../lib/baker"

context "Baker" do
  specify "should check that its running from a cookbooks project" do
    @root = File.dirname(__FILE__)+"/fixtures/cookbooks-empty"
    @baker = Baker.new(:host => "test_server", :root => @root)
    File.directory?(@root+"/cookbooks").should == false
    should.raise(NotCookbookProject) { @baker.run }
  end
  
  # specify "should upload baker configs and recipes" do
  #   Net::SSH.stubs(:configuration_for).returns({})
  #   Net::SSH.expects(:start).with(@server.host, "default-user", @options).returns(success = Object.new)
  #   
  #   Net::SSH.start(@host, @user) do |ssh|
  #     upload_chef_configs(ssh)
  #     upload_recipes(ssh)
  #     run_chef(ssh)
  #   end
  #   
  # end
end
