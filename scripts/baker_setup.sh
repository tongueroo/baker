#!/bin/bash -ex

# this script can be ran incrementally. if the packages are already installed, it will do nothing.

# install essential libraries
type -P make &>/dev/null || { 
  apt-get -q -y install build-essential
}

# install ruby
type -P ruby &>/dev/null || { 
  apt-get update
  apt-get -q -y install ruby1.8 ruby1.8-dev libopenssl-ruby
  ln -s /usr/bin/ruby1.8 /usr/bin/ruby
}

# install rubygems
type -P gem &>/dev/null || {
  wget http://files.rubyforge.vm.bytemark.co.uk/rubygems/rubygems-1.4.2.tgz
  tar xzvf rubygems-1.4.2.tgz
  cd rubygems-1.4.2 && ruby setup.rb
  ln -s /usr/bin/gem1.8 /usr/bin/gem
  gem update --system
  rm -rf rubygems-1.4.2
  rm -f rubygems-1.4.2.tgz
}

# install chef-solo
type -P chef-solo &>/dev/null || {
  gem install --no-ri --no-rdoc chef
}

