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

module ServerBackup
  class BackupSystemRestore < Chef::Knife

    deps do
      require 'chef/knife/core/object_loader'
      require 'chef/node'
      require 'chef/api_client'
    end

    banner "knife backup system restore NODENAME"

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

      ui.warn "This will overwrite existing data!"
      ui.warn "Backup is at least 1 day old" if (Time.now - File.atime(config[:backup_dir])) > 86400
      ui.confirm "Do you want to restore backup, possibly overwriting exisitng data"
      chef_node_or_client_name = name_args.first 
      restore(chef_node_or_client_name, Chef::Node)
      restore(chef_node_or_client_name, Chef::ApiClient)
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
