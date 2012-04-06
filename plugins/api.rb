class Api < Chef::Knife
  banner "knife api METHOD PATH [REQUEST BODY] (options)"

  deps do
    require 'chef/webui_user'
    require 'chef/api_client'
  end

  option :raw,
  :long => "--raw",
  :short => "-R",
  :description => "Show raw response. Only applies to GET",
  :default => false

  def run
    method, path, request = @name_args
    if !method || !path
      show_usage
      ui.fatal "You must specify a method and a path"
      exit 1
    end

    response = case method.downcase.to_sym
               when :get
                 if config[:raw]
                   ::File.read rest.get_rest path, true
                 else
                   rest.get_rest path
                 end
               when :delete
                 ui.confirm "DELETE is a destructive method.  Do you want to call DELETE on #{path}"
                 rest.delete_rest path
               when :post
                 raise ArgumentError, "Request Body Required" unless request
                 # HACK: Use eval to turn string into a Hash
                 rest.post_rest path, eval(request)
               when :put
                 raise ArgumentError, "Request Body Required" unless request
                 rest.put_rest path, eval(request)
               else
                 raise ArgumentError, "Unknown method #{method}"
               end
    ui.output(ui.format_for_display response)
  end
end
