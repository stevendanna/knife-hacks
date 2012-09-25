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
# This plugin will backup a single node. You can specify -A to include the
# api client associated with the node being backed up. This plugin will
# also restore a node/api client.
#
# Restoring api clients in hosted or private chef is not advised as it creates
# association/permission problems between the client and the node. The suggestion
# is to provide a validation pem and let the node re register, creating a new
# api client. 
#
# Migrating a Node: you can pass -c /path/to/new/knife.rb to us this tool for
# migrating a node to a new chef server.
#
# How I use this tool:
# knife backup node nodename
# knife bootstrap nodename -d migrate -c /path/to/new/chef/servers/knife.rb
# knife backup node restore nodename -c /path/to/new/chef/servers/knife.rb
#

require 'chef/node'
require 'chef/api_client'

module ServerBackup
  class BackupNode < Chef::Knife

    deps do
      require 'fileutils'
    end

    banner "knife backup node NODENAME [-d DIR] [--api-client | -A]" 

    # A migrate option would be kick ass - take a new knife.rb for a new chef-server and use that as the restore target
    option :backup_dir,
      :short => "-d DIR",
      :long => "--backup-directory DIR",
      :description => "Store backup data in DIR.  DIR will be created if it does not already exist.",
      :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")

    option :api_client,
      :short => "-A",
      :long => "--api-client",
      :description => "Include API Client object associated with the node in the backup",
      :default => false

    def run
      unless name_args.size == 1
        puts "You need to provide a NODENAME to backup"
        show_usage
        exit 1
      end

    chef_node_or_client_name = name_args.first 
    backup(chef_node_or_client_name, Chef::Node)
    backup(chef_node_or_client_name, Chef::ApiClient) if config[:api_client]
    end

    def backup(chef_node_or_client_name, klass)
      klass_name = klass.to_s.split(/::/).last.downcase
      backup_dir = File.join(config[:backup_dir], 'single_nodes')
      dir = File.join(backup_dir, klass_name)
      FileUtils.mkdir_p(dir)
      ui.msg "Backing up #{chef_node_or_client_name} #{klass_name}"
      chef_node_or_client_object = klass.load chef_node_or_client_name
      File.open(File.join(dir, "#{chef_node_or_client_name}.json"), 'w') do |file|
        file.print(chef_node_or_client_object.to_json)
      end
    end

  end

  class BackupNodeRestore < Chef::Knife

    deps do
      require 'chef/knife/core/object_loader'
    end

    banner "knife backup node restore NODENAME"

    option :backup_dir,
      :short => "-d DIR",
      :long => "--backup-directory DIR",
      :description => "Restore backup data from DIR.",
      :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")

    def run
      unless name_args.size == 1
        puts "You need to provide a NODENAME to backup"
        show_usage
        exit 1
      end

      chef_node_or_client_name = name_args.first 
      ui.warn "This will overwrite existing data!"
      ui.warn "Backup is at least 1 day old" if (Time.now - File.atime(File.join(config[:backup_dir], 'single_nodes', 'node', "#{chef_node_or_client_name}.json"))) > 86400
      ui.confirm "Do you want to restore backup, possibly overwriting exisitng data"
      restore(chef_node_or_client_name, Chef::Node)
      restore(chef_node_or_client_name, Chef::ApiClient) if File.exists?(File.join(config[:backup_dir], 'single_nodes', 'apiclient', "#{chef_node_or_client_name}.json"))
    end

    def restore(chef_node_or_client_name, klass)
      loader = Chef::Knife::Core::ObjectLoader.new(klass, ui)
      klass_name = klass.to_s.split(/::/).last.downcase
      backup_dir = File.join(config[:backup_dir], 'single_nodes')
      dir = File.join(backup_dir, klass_name)
      ui.msg "Restoring #{chef_node_or_client_name} #{klass_name}"
      updated = loader.load_from(dir, "#{chef_node_or_client_name}.json")
      updated.save
    end
  end
end
