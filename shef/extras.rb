#
# Shef Extras: A few features to make interactive debugging
#              with chef a bit easier.
#
# Author: Steven Danna <steve@opscode.com>
#

module ShefExtras
  module Recipe

    def load_node_run_list
      node.run_list.expand(node.chef_environment).recipes.each do |r|
        include_recipe r
      end
    end

    def ordered_resources
      run_context.resource_collection.all_resources.map { |r| r.to_s }
    end

    # insert_break: Inserts break point before
    # or after designated resource.  Requires
    # A monkey-patched resource_collection to make
    # manipulation a bit easier.
    def insert_break(preposition, resource)
      index = case preposition.to_sym
              when :before
                ordered_resources.index(resource)
              when :after
                ordered_resources.index(resource) + 1
              end

      if index.nil?
        Chef::Log.error("Can't find index needed to place break #{preposition} #{resource}")
        return false
      end

      brk = breakpoint "break-#{preposition}-#{resource}"

      # First remove the breakpoint from the end of the
      # resource collection.
      run_context.resource_collection.all_resources.pop
      run_context.resource_collection.resources_by_name.delete("[#{brk.name}]")

      # Change the name to something reasonable
      # give break a resource_name to make it prettier
      brk.name "break-#{preposition}-#{resource}"
      brk.resource_name = :break

      # Put break resource in resource collection
      run_context.resource_collection.all_resources.insert(index, brk)
      # Rewrite resources_by_name, I'm not sure how necessary this is.
      (0..(run_context.resource_collection.all_resources.length - 1)).each  do |idx|
        run_context.resource_collection.resources_by_name[run_context.resource_collection.all_resources[idx].to_s] = idx
      end
      Chef::Log.info("Breakpoint added #{preposition} #{resource}")
      brk
    end

    def setup_run
      run_chef
      load_node_run_list
      chef_run
    end
  end

  # Creating an accessor for resources_by_name
  # makes the insert_break function slightly more sane.
  module ResourceCollection
    attr_accessor :resources_by_name
  end

  # This is needed to provide nice names for
  # our break resources in insert_break
  module Resource
    attr_writer :resource_name
  end

  module_function

  def load
    Chef::Resource.send(:include, ShefExtras::Resource)
    Chef::ResourceCollection.send(:include, ShefExtras::ResourceCollection)
    Chef::Recipe.send(:include, ShefExtras::Recipe)
    Chef::Log.info("ShefExtras loaded!")
  end

end
