module UserPlugin
  class UserList < Chef::Knife
    banner 'knife user list'
    def run
      api_endpoint = "users"
      users = rest.get_rest(api_endpoint).map { |u| u["user"]["username"] }
      ui.output(format_for_display(users.sort))
    end
  end
end
