# expanded_run_list.rb: Show expanded run list of given node.
puts nodes.show(ARGV[2]).expand!('server').recipes
exit 0
