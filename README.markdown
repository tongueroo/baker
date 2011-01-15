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
│   ├── node.json
│   └── solo.rb
└── cookbooks
    ├── example_recipe1
    │    └── recipes
    │        └── default.rb
    └── example_recipe2
        └── recipes
            └── default.rb
</pre>

config/node.json and config/solo.rb are important.  These are the configurations that get passed to the chef run that will tell it which recipes to run.  

You need configure solo.rb to have this:

solo.rb: 

<pre>
file_cache_path "/tmp/baker"
cookbook_path "/tmp/baker/recipes/cookbooks"
</pre>

node.json will determine what recipes you'll run:

config/node.json: 

Example:

https://github.com/tongueroo/baker/blob/master/test/fixtures/cookbooks-valid/config/node.json

Usage
-------

Once all that is set up, you can run baker and that will upload the recipes to the server and run them.
Errors are logged to /var/log/baker.chef.log on the server and baker.log locally.

<pre>
bake [server]
</pre>
