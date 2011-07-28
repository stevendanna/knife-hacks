module UserPlugin
  class UserInviteList < Chef::Knife
    banner 'knife user invite list'

    def run
      api_endpoint = "association_requests/"
      invited_users = rest.get_rest(api_endpoint).map { |i| i['username'] }
      output(format_for_display(invited_users))
    end
  end
end
