# Shef Scripts and Helpers

This directory includes scripts and helper classes that I have found
helpful when debugging problems.  Unlike this `exec` folder, the
scripts here focus on tools I typically need when working
interactively in Shef.

# Configuration

Adding the following to the configuration file you will be using with
Shef (such as your knife.rb or shef.rb file) will place
`~/src/knife-hack` in Ruby's load path, allowing you to more easily
use the libraries in the shef directory.

```ruby
unless defined?(Shef).nil?
  $: << File.expand_path("~/src/knife-hacks/")
end
```

# Raw API Requests

`raw_request.rb` creates a raw_api object that is similar to the api
object, but shows you the raw JSON that the API returns rather than
returning a Chef object.  Often, by creating a Chef object (such as a
Chef::Node object) from the API response, the default api object hides
possible problems with API responses.

To use this:

    require 'shef/raw_rest'
    raw_api = ShefRawREST.new(Chef::Config[:chef_server_url])
    raw_api.get("nodes")

# Shef Extras

The ShefExtras library provides features that make interactive
debugging in Shef a bit easier.

## Setup

```ruby
require 'shef/extras'
ShefExtras.load
```
## Recipe Mode
The majority of the features in ShefExtras are relevant in
recipe-mode.

### setup_run
`setup_run` provides an easy way to debug problems with an existing
node. `setup_run` starts a chef run, expands the node's run_list, and places
the resources in the resource_collection.

```ruby
require 'shef/extras'
ShefExtras.load
recipe
# Now in recipe mode
setup_run
# We've now loaded all of our recipes
# And started a chef run.  We can step through it.
chef_run.step
```
### ordered_resources
`ordered_resources` prints the list of resources in the order chef
will run them.

### insert_break(preposition, resource)
`insert_break` allows you to insert a breakpoint before or after a
resource in the resource_collection.

    chef:recipe > pp ordered_resources
    ["log[a]", "log[b]", "log[c]"]
    chef:recipe > insert_break :before, "log[c]"
    [Sat, 28 Jan 2012 19:19:28 -0800] INFO: Breakpoint added before log[c]
    chef:recipe > insert_break :after, "log[a]"
    [Sat, 28 Jan 2012 19:19:37 -0800] INFO: Breakpoint added after log[a]
    chef:recipe > pp ordered_resources
    ["log[a]",
     "break[break-after-log[a]]",
     "log[b]",
     "break[break-before-log[c]]",
     "log[c]"]


This is most useful when you have used `setup_run` to load the
resources from a node's run_list.
