module UserPlugin
  class UserInviteList < Chef::Knife
    banner 'knife user invite list'

    def run
      api_endpoint = "association_requests/"
      invited_users = rest.get_rest(api_endpoint).map { |i| i['username'] }
      ui.output(invited_users)
    end
  end
end
