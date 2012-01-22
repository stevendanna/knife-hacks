node.run_list.expand(node.chef_environment).recipes.each { |r| include_recipe r }
