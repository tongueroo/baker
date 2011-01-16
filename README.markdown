Baker
=======

A simple way to run chef recipes on one server.

Install
-------

<pre>
gem install baker --source http://gemcutter.org --no-ri --no-rdoc # sudo if you need to
</pre>

Usage
-------

I. setup ssh key

Set up your ssh key on the server so you can login into the box without a password.  The gem only supports logging in via a .ssh/config shortcut.  Your .ssh/config should look something like this:

<pre>
Host server_name
  Hostname     xxx.xxx.xxx.xxx
  Port         22  
  User         root
</pre>

II. install chef

Can install chef with baker itself.  

<pre>
$ bake --setup server_name
</pre>

III. run chef recipes

Create a cookbooks project.  Here's an example of a cookbooks project structure:

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

config/solo.rb looks like this: 

<pre>
file_cache_path "/tmp/baker"
cookbook_path "/tmp/baker/recipes/cookbooks"
</pre>

config/node.json looks like this:

<pre>
{
  "ec2": true,
  "environment": {"name":"production"},
  "mysql_root_password":"whatever",
  "packages":[
    {"name": "git-core"},
    {"name": "curl"}
  ],
  "gems":[
  	{"name": "rails", "version": "3.0.3"},
    {"name": "bundler"}
  ],
  "recipes":[
    "example_recipe1",
    "example_recipe2"
  ]
}
</pre>

To actually run the chef recipes, cd into the cookbooks project folder and run this command:

<pre>
$ bake server_name
</pre>

After running chef you should check the /var/log/baker.chef.log on the server itself for possible errors.

