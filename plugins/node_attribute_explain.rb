#
# Author:: Steven Danna (steve@opscode.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# knife node attribute explain NODENAME ATTRIBUTE_SPEC

# DANGER: This was a quick hack that I have found useful on multiple occasions.
# But, it is likely to break, can be wrong, and is ugly.
#

class NodeAttributeExplain < Chef::Knife

  banner "knife node attribute explain NODE_NAME ATTRIBUTE_SPEC"

  deps do
    require 'chef/node'
    require 'chef/knife/core/generic_presenter'
    require 'chef/cookbook/cookbook_collection'
    require 'chef/run_context'
    require 'chef/cookbook_version'
    require 'chef/checksum_cache'
  end

  def run

    @node_name, @attr_spec = name_args

    if ! @node_name || ! @attr_spec
      ui.fatal "You must specify both a node name and an attribute"
      show_usage
      exit 1
    end

    # Tracking which roles were already applied
    @applied_role = []
    # Collection of warnings to display at the end, based on known bugs
    @collected_warnings = []
    # Count changes in attribute files to warn about CHEF-2904
    @change_count = 0

    @presenter = Chef::Knife::Core::GenericPresenter.new(self, config)

    build_context
    print_initial_state
    analyze_attributes
    print_warnings
  end

  def node
    @node ||= Chef::Node.load(@node_name)
  end

  def build_context
    @run_list_expansion = node.expand!('server')
    @expanded_run_list_with_versions = @run_list_expansion.recipes.with_version_constraints_strings
    cookbook_hash = sync_cookbooks
    run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new(cookbook_hash))
  end

  def print_initial_state
    ui.msg "Intitial Attribute State:"
    @previous_state = current_attr_state
    ui.output @previous_state
  end

  def analyze_attributes
    check_for_auto_attr
    process_reset
    process_attribute_files
    # This is where it starts to get really suspect
    process_environment_default
    process_roles
    process_environment_override
  end


  def check_for_state_change(sender_msg)
    current = current_attr_state
    if current != @previous_state
      @previous_state = current
      ui.msg "Attribute state changed by #{sender_msg}:"
      ui.output @previous_state
      true
    else
      false
    end
  end

  # Adds a warning to our warning collection if the attribute appears to be an automatic
  # attribute.  Automatic attributes are set by Ohai and this tool is largely useless when
  # trying to determine why they took on a particular value.
  def check_for_auto_attr
    auto_attr = @presenter.extract_nested_value(node.automatic, @attr_spec)
    if ! auto_attr.nil?
      @collected_warnings << "Attribute is set at automatic level.  This means it is likely set by Ohai."
    end
  end

  # Chef-client resets defaults and overrides at the beginning of
  # a chef-client run.
  def process_reset
    node.reset_defaults_and_overrides
    check_for_state_change("Default and Override Reset")
  end

  def process_attribute_files
    node.cookbook_collection.values.each do |cookbook|
      cookbook.segment_filenames(:attributes).each do |segment_filename|
        node.from_file(segment_filename)
        if check_for_state_change "attribute file #{segment_filename} in #{cookbook.name}"
          @change_count += 1
        end

        if @change_count > 1
          @collected_warnings << "Attribute set in multiple attribute files. Attribute files can load in a non-deterministic order. This can affect the final value. (CHEF-2903)"
        end
      end
    end
  end

  def process_environment_default
    load_chef_environment_object = (node.chef_environment == "_default" ? nil : Chef::Environment.load(node.chef_environment))
    environment_default_attrs = load_chef_environment_object.nil? ? {} : load_chef_environment_object.default_attributes
    node.default_attrs = Chef::Mixin::DeepMerge.merge(node.default_attrs, environment_default_attrs)
    check_for_state_change "deep merge of default attribute in environment #{node.chef_environment}"
  end

  # This is technically processing role attributes differently that they are processed
  # during an actual run.  During the actual run, all of the default role attributes are merged into a single
  # Mash and then that Mash is merged onto the node.  A similar process occurs for the override attributes.
  # Here, we are merging the attributes from each role onto the node seperately.
  def process_roles(items=node.run_list.run_list_items.dup)
    if entry = items.shift
      if entry.type == :role && role = inflate_role(entry.name)
        process_roles(role.run_list_for(@environment).run_list_items)
        node.default_attrs = Chef::Mixin::DeepMerge.merge(node.default_attrs, role.default_attributes)
        check_for_state_change "deep merge of default attribute in role #{entry.name}"
        node.override_attrs = Chef::Mixin::DeepMerge.merge(node.override_attrs, role.override_attributes)
        check_for_state_change "deep merge of override attribute in role #{entry.name}"
      end
      process_roles(items)
    end
  end

  def process_environment_override
    load_chef_environment_object = (node.chef_environment == "_default" ? nil : Chef::Environment.load(node.chef_environment))
    environment_override_attrs = load_chef_environment_object.nil? ? {} : load_chef_environment_object.override_attributes
    @override_attrs = Chef::Mixin::DeepMerge.merge(node.override_attrs, environment_override_attrs)
    check_for_state_change "deep merge of override attributes in environment #{node.chef_environment}"
  end

  def print_warnings
    @collected_warnings.each do |warning|
      ui.warn warning
    end
  end

  def current_attr_state
    { "FINAL"     => @presenter.extract_nested_value(node, @attr_spec),
      "default"   => @presenter.extract_nested_value(node.default_attrs, @attr_spec),
      "normal"    => @presenter.extract_nested_value(node.normal_attrs, @attr_spec),
      "override"  => @presenter.extract_nested_value(node.override_attrs, @attr_spec),
      "automatic" => @presenter.extract_nested_value(node.automatic_attrs, @attr_spec)}
  end

  # WARNING
  # The following functions are mostly copy/pasta'd from the run_list_expansion, run_context,
  # and node classes.

  private
  def sync_cookbooks
    Chef::Log.debug("Synchronizing cookbooks")
    cookbook_hash = rest.post_rest("environments/#{node.chef_environment}/cookbook_versions",
                                     {:run_list => @expanded_run_list_with_versions})
    Chef::CookbookVersion.sync_cookbooks(cookbook_hash)
    Chef::Config[:cookbook_path] = File.join(Chef::Config[:file_cache_path], "cookbooks")
    cookbook_hash
  end

  def inflate_role(role_name)
    return false if @applied_role.include?(role_name) # Prevent infinite loops
    @applied_role << role_name
    fetch_role(role_name)
  end

  def fetch_role(name)
    rest.get_rest("roles/#{name}")
  rescue Net::HTTPServerException => e
    if e.message == '404 "Not Found"'
      ui.error "Role #{name} not found"
    else
      raise
    end
  end
end
