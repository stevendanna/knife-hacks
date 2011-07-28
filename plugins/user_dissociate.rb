module UserPlugin
  class UserDissociate < Chef::Knife
    banner 'knife user dissociate USERNAMES'

    def run
      if name_args.length < 1
        show_usage
        ui.fatal("You must specify a username")
        exit 1
      end
      users = name_args
      users.each do |u|
        api_endpoint = "users/#{u}"
        rest.delete_rest(api_endpoint)
      end
    end
  end
end
