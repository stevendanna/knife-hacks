# knife-exec script to clean node and clients
# from terminated ec2 instances.
#

require 'fog'
require 'chef/knife'
require 'chef/shef/ext'

class Cleanup < Chef::Knife
  def clean()
    Shef::Extensions.extend_context_object(self)
    nodes_to_clean = Array.new
    clients_to_clean = Array.new

    #Add all nodes that are/were EC2 instances
    nodes.all {|n| nodes_to_clean.push(n) if n.has_key?("ec2")}

    #Get all EC2 instances
    #stolen from knife-ec2
    connection = Fog::Compute.new(:provider => 'AWS',
                                  :aws_access_key_id => Chef::Config[:knife][:aws_access_key_id],
                                  :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
                                  :region => Chef::Config[:knife][:region] || config[:region])

    ec2_id_list = connection.servers.all.map { |s| s.id.to_s unless s.state == "terminated"}
    ec2_id_list.compact!

    #Filter active EC2 instances from node list
    nodes_to_clean = nodes_to_clean.select { |n| ec2_id_list.all?{ |s| n['ec2']['instance_id'] && s != n['ec2']['instance_id']}}

    #Get corresponding clients
    clients_to_clean = nodes_to_clean.map { |n| clients.show(n.name) }

    #Confirm with User
    ui.msg "Nodes For Deletion:"
    pp nodes_to_clean
    ui.msg "-"*6
    ui.msg "Clients for Deletion:"
    pp clients_to_clean
    ui.msg "-"*6
    ui.confirm("Do you want to delete these objects")

    # Delete!
    nodes_to_clean.each { |n| n.destroy }
    clients_to_clean.each { |c| c.destroy }

  end
end

c = Cleanup.new
c.clean
exit 0
