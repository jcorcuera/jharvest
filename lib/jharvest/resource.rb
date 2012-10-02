require 'base64'
require 'bigdecimal'
require 'date'
require 'net/http'
require 'net/https'
require 'time'
require 'active_support/core_ext/hash/conversions'

module JHarvest
  class Resource
    def initialize(opts)
      @subdomain = opts[:subdomain]
      @email     = opts[:email]
      @password  = opts[:password]
      @token     = opts[:token]
      @preferred_protocols = [true, false]
      connect!
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
      @token || Base64.encode64("#{@email}:#{@password}").delete("\r\n")
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
        @preferred_protocols.shift
        raise "Failed connection using http or https" if @preferred_protocols.empty?
        connect!
        request(path, method, body)
      else
        dump_headers = response.to_hash.map { |h,v| [h.upcase,v].join(': ') }.join("\n")
        raise "#{response.message} (#{response.code})\n\n#{dump_headers}\n\n#{response.body}\n"
      end
    end

    private

    def connect!
      port = has_ssl ? 443 : 80
      @connection = Net::HTTP.new("#{@subdomain}.harvestapp.com", port)
      @connection.use_ssl = has_ssl
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if has_ssl
    end

    def has_ssl
      @preferred_protocols.first
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
end
