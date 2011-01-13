Baker
=======

A simple way to run chef recipes on one server.

Install
-------

<pre>
gem install baker --source http://gemcutter.org --no-ri --no-rdoc # sudo if you need to
</pre>

Prerequisite
-------

You need to set up sshkeys on the server so you can ssh into the box without passwords.

On the server:

You'll need to make sure to have chef installed.

On the client:

First you need to be in a cookbooks project.  Here's an example of a mininum cookbooks project:

<pre>
├── config
│    └── baker
│        ├── node.json
│        └── solo.rb
└── cookbooks
    ├── example_recipe1
    │    └── recipes
    │        └── default.rb
    └── example_recipe2
        └── recipes
            └── default.rb
</pre>

config/baker/node.json and config/baker/solo.rb are important.  These are the configurations that get passed to the chef run that will tell it which recipes to run.  

You need configure solo.rb to have this:

solo.rb: 
file_cache_path "/tmp/baker"
cookbook_path "/tmp/baker/recipes/cookbooks"

node.json will determine what recipes you'll run:

config/baker/node.json:


Usage
-------

Once all that is set up, you can run baker and that will upload the recipes to the server and run them.
Errors are logged to /var/log/baker-chef-server.log and /var/log/baker-chef-client.log.

<pre>
bake <server>
</pre>
