module UserPlugin
  class UserShow < Chef::Knife
    banner 'knife user show [USERNAME]'

    attrs_to_show = []
    option :attribute,
    :short => "-a [ATTR]",
    :long => "--attribute [ATTR]",
    :proc => lambda {|val| attrs_to_show << val},
    :description => "Show attribute ATTR"
    

    def run
      if name_args.length < 1
        show_usage
        ui.fatal("You must specify a username.")
        exit 1
      end
      username = name_args[0]
      api_endpoint = "users/#{username}"
      user = rest.get_rest(api_endpoint)
      ui.output(ui.format_for_display(user))
    end
  end
end
