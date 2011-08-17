module UserPlugin
  class UserInviteAdd < Chef::Knife

    banner 'knife user invite add USERNAMES'

    def run
      if name_args.length < 1
        show_usage
        ui.fatal("You must specify a username.")
        exit 1
      end
      users = name_args[0]
      api_endpoint = "association_requests/"
      users.each do |u|
        body = {:user => u}
        rest.post_rest(api_endpoint, body)
      end
    end
  end
end
