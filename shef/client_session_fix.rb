# Temporary monkey-patch for CHEF-2467
# Ensure we call @run_context.load with the
# correct run_list_expansion
#
module Shef
  class ClientSession
    def rebuild_context
      @run_status = Chef::RunStatus.new(@node)
      Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::RemoteFileVendor.new(manifest, Chef::REST.new(Chef::Config[:server_url])) }
      cookbook_hash = @client.sync_cookbooks
      @run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new(cookbook_hash))
      @run_context.load(@node.run_list.expand(@node.chef_environment))
      @run_status.run_context = run_context
    end
  end
end
