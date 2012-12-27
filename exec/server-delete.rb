require 'fog'
def remove(name)

  # get some values from the node for future use
  mynode = nodes.show(name)
  instance_id = mynode[:ec2][:instance_id]
  zone_id = mynode[:route53][:zone_id]
  int_domain = mynode[:route53][:int_domain]
  aws_creds = Chef::EncryptedDataBagItem.load("passwords", "aws")

  puts "iid #{instance_id} zid #{zone_id} intd #{int_domain}"
  ## Delete the Route53 DNS record
  r53 = Fog::DNS::new( :provider => "aws",
                       :aws_access_key_id => aws_creds["aws_access_key_id"],
                       :aws_secret_access_key => aws_creds["aws_secret_access_key"])
  zone = r53.zones.get(zone_id)
  puts "looking for #{name}.#{int_domain}."
  record = zone.records.get("#{name}.#{int_domain}.")
  puts "found #{record}"
  if record.nil?
    puts "No DNS records found; skipping DNS deletion."
  else
    print "Deleting #{record.name} from DNS... "
    record.destroy
    puts "done."
  end

  # search for attached EBS volumes to delete after the node if they exist
  aws = Fog::Compute::new( :provider => "aws",
                           :aws_access_key_id => aws_creds["aws_access_key_id"],
                           :aws_secret_access_key => aws_creds["aws_secret_access_key"])
  # get all volumes that are attached to this node
  volumes = aws.volumes.select {|vol| vol.server_id == instance_id}
  if volumes.length.zero?
    puts "no volumes found."
  else
    puts "EBS Volumes are #{volumes.map {|vol| vol.id}}"
  end
  # volumes now contains an array of volume objects or []
  # these are stored for the end when, after the server's deleted, the then-unattached volumes can be deleted.

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

  volumes.each do |volume|
    # wait for the volume to detach from the instance we just killed
    print "Waiting for up to 5 minutes for the volume #{volume.id} to detach: "
    300.times do |n|
      if volume.ready?
        puts "destroying volume"
        volume.destroy
        break
      end
      print "."
      sleep 1
      volume.reload
    end
  end #volumes.each
  volumes = aws.volumes.select {|vol| vol.server_id == instance_id}
  unless volumes.length.zero?
    puts "Failed to destroy volumes: volumes still contain #{volumes.map {|vol| vol.id}}."
  end

end


remove(ARGV[2])
exit 0
