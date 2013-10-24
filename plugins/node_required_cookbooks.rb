class NodeRequiredCookbooks < Chef::Knife
  banner "knife node required cookbooks NODE_NAME"

  def run
    node_name = @name_args[0]

    if !node_name
      show_usage
      ui.fatal "You must specify a node name."
      exit 1
    end

    node = Chef::Node.load(node_name)

    # Expand node run_list
    run_list_expansion = node.run_list.expand(node.chef_environment)
    run_list = run_list_expansion.recipes.with_version_constraints_strings

    metadata = rest.post_rest("environments/#{node.chef_environment}/cookbook_versions",
                              :run_list => run_list)

    metadata.each do |name, ckbk|
      ui.output("#{name} #{ckbk.version}")
    end
  end
end
