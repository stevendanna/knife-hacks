#
# Author:: Steven Danna (steve@opscode.com)
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Adam Jacob (<adam@opscode.com>)
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

module ServerBackup
  class BackupExport < Chef::Knife

    deps do
      require 'fileutils'
    end

    banner "knife backup export [-d DIR]"

    option :backup_dir,
    :short => "-d DIR",
    :long => "--backup-directory DIR",
    :description => "Store backup data in DIR.  DIR will be created if it does not already exist.",
    :default => Chef::Config[:knife][:chef_server_backup_dir] ? Chef::Config[:knife][:chef_server_backup_dir] : File.join(".chef", "chef_server_backup")

    def run
      nodes
      roles
      data_bags
      environments
    end

    def nodes
      backup_standard("nodes", Chef::Node)
    end

    def roles
      backup_standard("roles", Chef::Role)
    end

    def environments
      backup_standard("environments", Chef::Environment)
    end

    def data_bags
      ui.msg "Backing up data bags"
      dir = File.join(config[:backup_dir], "data_bags")
      FileUtils.mkdir_p(dir)
      Chef::DataBag.list.each do |bag_name, url|
        FileUtils.mkdir_p(File.join(dir, bag_name))
        Chef::DataBag.load(bag_name).each do |item_name, url|
          ui.msg "Backing up data bag #{bag_name} item #{item_name}"
          item = Chef::DataBagItem.load(bag_name, item_name)
          File.open(File.join(dir, bag_name, "#{item_name}.json"), "w") do |dbag_file|
            dbag_file.print(item.raw_data.to_json)
          end
        end
      end
    end

    def backup_standard(component, klass)
      ui.msg "Backing up #{component}"
      dir = File.join(config[:backup_dir], component)
      FileUtils.mkdir_p(dir)
      klass.list.each do |component_name, url|
        next if component == "environments" && component_name == "_default"
        ui.msg "Backing up #{component} #{component_name}"
        component_obj = klass.load(component_name)
        File.open(File.join(dir, "#{component_name}.json"), "w") do |component_file|
          component_file.print(component_obj.to_json)
        end
      end
    end

  end
end
