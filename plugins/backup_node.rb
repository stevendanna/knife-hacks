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

require 'chef/node'
require 'chef/api_client'

module ServerBackup
  class BackupSystem < Chef::Knife

    deps do
      require 'fileutils'
    end

    banner "knife backup system NODENAME" 

    # A migrate option would be kick ass - take a new knife.rb for a new chef-server and use that as the restore target
    option :backup_dir,
    :short => "-d DIR",
    :long => "--backup-directory DIR",
    :description => "Store backup data in DIR.  DIR will be created if it does not already exist.",
    :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")


    def run
      unless name_args.size == 1
        puts "You need to provide a NODENAME to backup"
        show_usage
        exit 1
      end

    chef_node_or_client_name = name_args.first 
    backup(chef_node_or_client_name, Chef::Node)
    backup(chef_node_or_client_name, Chef::ApiClient)
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
end
