class ShefRawREST < Shef::ShefREST
  # A ShefRawREST object will return the actual
  # JSON returned from the API rather than a
  # Chef object. Useful for debugging.
  # This

  def initialize(url, client_name=Chef::Config[:node_name], signing_key_filename=Chef::Config[:client_key], options={})
    if Chef::VERSION != '0.10.8'
      Chef::Log.warn("ShefRawREST was created for Chef 0.10.8.  You may experience problems.")
    end
    super
  end

  def api_request(method, url, headers={}, data=false)
    json_body = data
    # Force encoding to binary to fix SSL related EOFErrors
    # cf. http://tickets.opscode.com/browse/CHEF-2363
    # http://redmine.ruby-lang.org/issues/5233
    json_body.force_encoding(Encoding::BINARY) if json_body.respond_to?(:force_encoding)
    headers = build_headers(method, url, headers, json_body)

    retriable_rest_request(method, url, json_body, headers) do |rest_request|
      response = rest_request.call {|r| r.read_body}

      if response.kind_of?(Net::HTTPSuccess)
        if response['content-type'] =~ /json/
          puts response.body.chomp
          return response.code
        else
          Chef::Log.warn("Expected JSON response, but got content-type '#{response['content-type']}'")
          response.body
        end
      elsif redirect_location = redirected_to(response)
        follow_redirect {api_request(:GET, create_url(redirect_location))}
      else
        if response['content-type'] =~ /json/
          exception = Chef::JSONCompat.from_json(response.body)
          msg = "HTTP Request Returned #{response.code} #{response.message}: "
          msg << (exception["error"].respond_to?(:join) ? exception["error"].join(", ") : exception["error"].to_s)
          Chef::Log.info(msg)
        end
        response.error!
      end
    end
  end
end

(raw_api = ShefRawREST.new(Chef::Config[:chef_server_url])) && true
