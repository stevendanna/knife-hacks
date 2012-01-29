# Tempoary fix for Shef's DoppelGangerClient class
# see CHEF-2896
#
#

module Shef
  class DoppelGangerClient
    def build_node
      Chef::Log.info("Building node object for #{@node_name}")
      @node = Chef::Node.load(node_name)
      ohai_data = @ohai.data.merge(@node.automatic_attrs)
      @node.consume_external_attrs(ohai_data,nil)
      @run_list_expansion = @node.expand!('server')
      @expanded_run_list_with_versions = @run_list_expansion.recipes.with_version_constraints_strings
      Chef::Log.info("Run List is [#{@node.run_list}]")
      Chef::Log.info("Run List expands to [#{@expanded_run_list_with_versions.join(', ')}]")
      @run_status = Chef::RunStatus.new(@node)
      @node
    end
  end
end
