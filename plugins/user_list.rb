module UserPlugin
  class UserList < Chef::Knife
    banner 'knife user list'
    def run
      users = Array.new
      api_endpoint = "users"
      users = rest.get_rest(api_endpoint).map { |u| u["user"]["username"] }
      output(format_for_display(users))
    end
  end
end
