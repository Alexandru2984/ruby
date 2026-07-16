require "net/http"

# Checks whether a bookmarked URL still responds. Reuses UrlMetadata's SSRF
# guard; a HEAD request is tried first, falling back to GET for servers that
# reject HEAD. 2xx/3xx counts as alive; auth walls (401/403) and rate
# limiting (429) are treated as alive too, since the link itself works.
class LinkChecker
  ALIVE_STATUSES = [ 401, 403, 405, 429 ].freeze

  Result = Struct.new(:status, :code, keyword_init: true) do
    def ok? = status == "ok"
  end

  class << self
    def check(url)
      uri = URI.parse(url)
      return broken unless uri.is_a?(URI::HTTP)
      return broken if UrlMetadata.blocked_host?(uri.host)

      response = request(uri, Net::HTTP::Head)
      response = request(uri, Net::HTTP::Get) if response.is_a?(Net::HTTPMethodNotAllowed) || response.is_a?(Net::HTTPNotImplemented)

      code = response.code.to_i
      alive = response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection) || ALIVE_STATUSES.include?(code)

      Result.new(status: alive ? "ok" : "broken", code: code)
    rescue URI::InvalidURIError, Timeout::Error, SystemCallError, SocketError,
           OpenSSL::SSL::SSLError, EOFError, Net::ProtocolError
      broken
    end

    private
      def request(uri, verb)
        Net::HTTP.start(uri.host, uri.port,
                        use_ssl: uri.scheme == "https",
                        open_timeout: UrlMetadata::OPEN_TIMEOUT,
                        read_timeout: UrlMetadata::READ_TIMEOUT) do |http|
          request = verb.new(uri.request_uri)
          request["User-Agent"] = "BookmarksBot/1.0 (+link check)"
          http.request(request)
        end
      end

      def broken
        Result.new(status: "broken", code: nil)
      end
  end
end
