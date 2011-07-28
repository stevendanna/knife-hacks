module UserPlugin
  class UserShow < Chef::Knife
    banner 'knife user show [USERNAME] (options)'

    option :all,
    :short => "-a",
    :long => "--all",
    :description => "Show all users"

    def run
      if name_args.length < 1 and ! config.has_key?(:all)
        show_usage
        ui.fatal("You must specify a username")
        exit 1
      end
      username = name_args[0]
      api_endpoint = "users/#{username}"
      user = rest.get_rest(api_endpoint)
      output(format_for_display(user))
    end
  end
end
