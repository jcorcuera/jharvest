module JHarvest
  class Resource
    def initialize(opts)
      @subdomain = opts[:subdomain]
      @email     = opts[:email]
      @password  = opts[:password]
      setup_connection
    end

    def headers
      {
        "Accept" => "application/xml",
        "Content-Type" => "application/xml; charset=utf-8",
        "Authorization" => "Basic #{auth_string}",
        "User-Agent" => "JHarvest"
      }
    end

    def auth_string
      Base64.encode64("#{@email}:#{@password}").delete("\r\n")
    end

    def request(path, method = :get, body = "")
      response = send_request( path, method, body)
      if response.class < Net::HTTPSuccess
        on_completed_request
        return response
      elsif response.class == Net::HTTPServiceUnavailable
        raise "Got HTTP 503 three times in a row" if retry_counter > 3
        sleep(response['Retry-After'].to_i + 5)
        request(path, method, body)
      elsif response.class == Net::HTTPFound
        raise "Failed connection"
      else
        dump_headers = response.to_hash.map { |h,v| [h.upcase,v].join(': ') }.join("\n")
        raise "#{response.message} (#{response.code})\n\n#{dump_headers}\n\n#{response.body}\n"
      end
    end

    private

    def setup_connection
      post = 443
      @connection = Net::HTTP.new("#{@subdomain}.harvestapp.com", port)
      @connection.use_ssl = true
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def send_request(path, method = :get, body = '')
      case method
      when :get
        @connection.get(path, headers)
      when :post
        @connection.post(path, body, headers)
      when :put
        @connection.put(path, body, headers)
      when :delete
        @connection.delete(path, headers)
      end
    end

    def on_completed_request
      @retry_counter = 0
    end

    def retry_counter
      @retry_counter ||= 0
      @retry_counter += 1
    end
end
