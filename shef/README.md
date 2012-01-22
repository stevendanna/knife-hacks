# Shef Scripts and Helpers

This directory includes scripts and helper classes that I have found
helpful when debugging problems.  Unlike this `exec` folder, the
scripts here focus on tools I typically need when working
interactively in Shef.

# Raw API Requests

`raw_request.rb` creates a raw_api object that is similar to the api
object, but shows you the raw JSON that the API returns rather than
returning a Chef object.  Often, by creating a Chef object (such as a
Chef::Node object) from the API response, small differences in the
actual API response can be hidden.

To use this:

    eval(File.read("/path/to/knife-hacks/shef/raw_rest.rb"))
    raw_api.get("nodes")

# Load Node's Run List

`load_run_list.rb` loads the node's entire run_list, allowing you to step
through the full chef-run for that node more easily.
