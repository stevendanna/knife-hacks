require 'chef/node'
nodes.find(:name => ARGV[2]).each do |n|
  puts "Reseting #{n.name}"
  name = n.name
  n = Chef::Node.new
  n.name(name)
  n.save
end
exit 0
