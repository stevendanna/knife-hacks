#
# Author:: Cliff Erson (him@clifferson.com)
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
# About this Plugin:
#
# This plugin will backup all nodes in a given environment plus the
# environment file. You can specify -A to include the api client associated
# with the nodes being backed up. This plugin will also restore an environment
# and its associated nodes/api clients.
#
# Restoring api clients in hosted or private chef is not advised as it creates
# association/permission problems between the client and the node. The suggestion
# is to provide a validation pem and let the node re register, creating a new
# api client. 
#
# Migrating Environments and Nodes: you can pass -c /path/to/new/knife.rb to
# us this tool for migrating env's and nodes to a new chef server.
#
# How I use this tool:
# knife backup envnodes my_env
# knife bootstrap -d migrate ... (Use a bootstapper to change the chef-client config on each node)
# knife backup envnodes restore my_env -c /path/to/new/chef/servers/knife.rb
#

require 'chef/node'
require 'chef/api_client'
require 'chef/environment'

module ServerBackup
  class BackupEnvnodes < Chef::Knife

    deps do
      require 'fileutils'
    end

    banner "knife backup envnodes ENVNAME [-d DIR] [--api-client | -A]" 

    option :backup_dir,
      :short => "-d DIR",
      :long => "--backup-directory DIR",
      :description => "Store backup data in DIR.  DIR will be created if it does not already exist.",
      :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")

    option :api_client,
      :short => "-A",
      :long => "--api-client",
      :description => "Include API Client objects associated with each node in the backup",
      :default => false

    def run
      unless name_args.size == 1
        puts "You need to provide a ENVNAME to backup"
        show_usage
        exit 1
      end

    chef_env = name_args.first 
    backup_env(chef_env)
    end

    def backup_env(chef_env)
      query_nodes = Chef::Search::Query.new
      query = "chef_environment:#{chef_env}"

      query_nodes.search('node', query) do |node_item|
        backup(node_item.name, Chef::Node, chef_env)
        backup(node_item.name, Chef::ApiClient, chef_env) if config[:api_client]
      end

      dir = File.join(config[:backup_dir], "nodes_in_env/#{chef_env}")
      FileUtils.mkdir_p(dir)
      env = Chef::Environment.load(chef_env)
      ui.msg "Backing up #{chef_env} environment"
      File.open(File.join(dir, "#{chef_env}.json"), 'w') do |file|
        file.print(env.to_json)
      end
    end


    def backup(chef_node_or_client_name, klass, env='_default')
      klass_name = klass.to_s.split(/::/).last.downcase
      backup_dir = File.join(config[:backup_dir], "nodes_in_env/#{env}")
      dir = File.join(backup_dir, klass_name)
      FileUtils.mkdir_p(dir)
      ui.msg "Backing up #{chef_node_or_client_name} #{klass_name}"
      chef_node_or_client_object = klass.load chef_node_or_client_name
      File.open(File.join(dir, "#{chef_node_or_client_name}.json"), 'w') do |file|
        file.print(chef_node_or_client_object.to_json)
      end
    end

  end

  class BackupEnvnodesRestore < Chef::Knife

    deps do
      require 'chef/knife/core/object_loader'
    end

    banner "knife backup envnodes restore ENVNAME [-d DIR] [--api-client | -A]"

    option :backup_dir,
      :short => "-d DIR",
      :long => "--backup-directory DIR",
      :description => "Store backup data in DIR.  DIR will be created if it does not already exist.",
      :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")

    option :api_client,
      :short => "-A",
      :long => "--api-client",
      :description => "Include API Client objects associated with each node in the backup",
      :default => false


    def run
      unless name_args.size == 1
        puts "You need to provide a NODENAME to backup"
        show_usage
        exit 1
      end

      chef_env = name_args.first 
      ui.warn "This will overwrite existing data!"
      ui.warn "Backup is at least 1 day old" if (Time.now - File.atime(File.join(config[:backup_dir], 'nodes_in_env', chef_env, "#{chef_env}.json"))) > 86400
      ui.confirm "Do you want to restore backup, possibly overwriting exisitng data"

      klasses = [Chef::Environment, Chef::Node]
      klasses << Chef::ApiClient if config[:api_client]
      klasses.each do |klass|
        restore(chef_env, klass)
      end
    end


    def restore(env='_default', klass)
      loader = Chef::Knife::Core::ObjectLoader.new(klass, ui)
      klass_name = klass.to_s.split(/::/).last.downcase
      ui.msg "Restoring #{klass_name}"
      backup_dir = File.join(config[:backup_dir], 'nodes_in_env', env)
      if klass == Chef::Environment
        dir = backup_dir
        files = Dir.glob(File.join(dir, "#{env}.json"))
      else
        dir = File.join(backup_dir, klass_name)
        files = Dir.glob(File.join(dir, "*.json"))
      end
      files.each do |f|
        ui.msg "Updating #{klass_name} from #{f}"
        updated = loader.load_from(dir, f)
        updated.save
      end
    end
  end
end
