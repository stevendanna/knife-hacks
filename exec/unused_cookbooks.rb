# unused_cookbooks.rb: List cookbooks that are not used by any nodes.
#

# First, we get a list of all the cookbooks
all_cookbooks = api.get("cookbooks").keys

used_cookbooks = Array.new

# Next, we expand the run list of each node,
# and use the API to determine cookbook
# dependencies.
nodes.all do |n|
  expanded_run_list = n.expand!('server').recipes
  cookbook_hash = api.post("environments/#{n.chef_environment}/cookbook_versions",
                           {:run_list => expanded_run_list})
  used_cookbooks += cookbook_hash.keys
end

# Remove duplicates
used_cookbooks.uniq!

# Diff the two lists
puts "Unused Cookbooks:"
puts all_cookbooks - used_cookbooks
exit 0
