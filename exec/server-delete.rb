require 'fog'
def remove(name)

  ## Delete the Server
  delete_ec2 = Chef::Knife::Ec2ServerDelete.new()
  delete_ec2.name_args = [nodes.show(name)['ec2']['instance_id']]
  delete_ec2.run

  ## Delete the Node
  delete_node = Chef::Knife::NodeDelete.new()
  delete_node.name_args = [name]
  delete_node.run

  ## Delete the client
  delete_client = Chef::Knife::ClientDelete.new
  delete_client.name_args = [name]
  delete_client.run

  ## Add code to remove CloudKick here

end


remove(ARGV[2])
