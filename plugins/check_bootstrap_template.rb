#
# chef_bootstrap_template.rb: Print out the rendered template
#   for testing purposes.
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


require 'chef/knife'

class Chef
  class Knife
    class CheckBootstrapTemplate < Knife

      deps do
        require 'chef/knife/bootstrap'
        require 'chef/knife/core/bootstrap_context'
        require 'erubis'
      end

      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      banner "knife check bootstrap template TEMPLATE_NAME"

      def run
        b = Chef::Knife::Bootstrap.new
        b.config = config
        b.config[:distro] = @name_args[0]
        puts b.ssh_command
      end

    end
  end
end
