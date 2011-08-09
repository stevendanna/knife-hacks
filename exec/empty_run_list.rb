# empty_run_list.rb: Reset the run list of any node that  matches the
#                search based on name.
# DANGER: WILl EAT YOUR CHILDREN!

require 'chef/run_list'
nodes.find(:name => ARGV[2]).each do |n|
  puts "Clearing runlist of #{n.name}"
  n.run_list = Chef::RunList.new()
  n.save
end
exit 0
