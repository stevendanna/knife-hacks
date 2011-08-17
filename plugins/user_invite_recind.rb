module UserPlugin
  class UserInviteRecind < Chef::Knife
    banner 'knife user invite recind [USERNAMES] (options)'

    option :all,
    :short => "-a",
    :long => "--all",
    :description => "Recind all invites!"

    def run
      if name_args.length < 1 and ! config.has_key?(:all)
        show_usage
        ui.fatal("You must specify a username.")
        exit 1
      end
      # To recind we need to send a DELETE to
      # association_requests/INVITE_ID
      # For user friendliness we look up the invite ID
      # based on username.
      @invites = Hash.new
      usernames = name_args
      rest.get_rest("association_requests").each { |i| @invites[i['username']] = i['id'] }
      if config.has_key?(:all)
        ui.confirm("Are you sure you want to recind all association requests")
        @invites.each do |u,i|
          rest.delete_rest("association_requests/#{i}")
        end
      else
        ui.confirm("Are you sure you want to recind the association requests for: #{usernames.join(', ')}")
        usernames.each do |u|
          if @invites.has_key?(u)
            rest.delete_rest("association_requests/#{@invites[u]}")
          else
            ui.fatal("No association request for #{u}.")
            exit 1
          end
        end
      end
    end
  end
end
