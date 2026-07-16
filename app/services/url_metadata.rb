require "ipaddr"
require "net/http"
require "resolv"

# Fetches page metadata (title, description, favicon) for a bookmarked URL.
#
# Defensive by design, since it fetches arbitrary user-supplied URLs from the
# server: private/loopback/link-local hosts are refused (SSRF), redirects are
# re-checked hop by hop, and responses are size- and time-capped.
class UrlMetadata
  Result = Struct.new(:title, :description, :favicon_url, keyword_init: true)

  # Raised for transient network conditions so the job can retry.
  class FetchError < StandardError; end

  MAX_REDIRECTS = 3
  MAX_BODY_BYTES = 512 * 1024
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5

  class << self
    # Returns a Result, or nil when the URL can't or shouldn't be summarized
    # (blocked host, non-HTML content, HTTP error status).
    def fetch(url)
      response, final_uri = get_following_redirects(url)
      return nil unless response.is_a?(Net::HTTPSuccess)
      return nil unless response["Content-Type"].to_s.match?(%r{\btext/html\b}i)

      parse(read_capped_body(response), final_uri)
    end

    def parse(html, base_uri)
      doc = Nokogiri::HTML(html)

      Result.new(
        title: text_of(doc.at_css("meta[property='og:title']")&.[]("content")) || text_of(doc.at_css("title")&.text),
        description: text_of(doc.at_css("meta[property='og:description']")&.[]("content")) ||
                     text_of(doc.at_css("meta[name='description']")&.[]("content")),
        favicon_url: favicon_from(doc, base_uri)
      )
    end

    def blocked_host?(host)
      return true if host.blank?

      addresses = ip_literal?(host) ? [ IPAddr.new(host) ] : Resolv.getaddresses(host).map { |ip| IPAddr.new(ip) }
      addresses.empty? || addresses.any? { |ip| ip.private? || ip.loopback? || ip.link_local? }
    rescue IPAddr::InvalidAddressError, Resolv::ResolvError
      true
    end

    private
      def get_following_redirects(url)
        uri = URI.parse(url)

        (MAX_REDIRECTS + 1).times do
          return nil unless uri.is_a?(URI::HTTP)
          return nil if blocked_host?(uri.host)

          response = perform_get(uri)

          if response.is_a?(Net::HTTPRedirection)
            location = response["Location"]
            return nil if location.blank?

            uri = URI.join(uri, location)
            next
          end

          return [ response, uri ]
        end

        nil
      rescue URI::InvalidURIError, ArgumentError
        nil
      end

      def perform_get(uri)
        Net::HTTP.start(uri.host, uri.port,
                        use_ssl: uri.scheme == "https",
                        open_timeout: OPEN_TIMEOUT,
                        read_timeout: READ_TIMEOUT) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)
          request["User-Agent"] = "BookmarksBot/1.0 (+metadata fetch)"
          request["Accept"] = "text/html"
          http.request(request)
        end
      rescue Timeout::Error, SystemCallError, SocketError, OpenSSL::SSL::SSLError, EOFError, Net::ProtocolError => e
        raise FetchError, "#{uri.host}: #{e.class}"
      end

      def read_capped_body(response)
        body = response.body.to_s
        body.byteslice(0, MAX_BODY_BYTES) || ""
      end

      def favicon_from(doc, base_uri)
        link = doc.css("link[rel]").find do |node|
          rel_tokens = node["rel"].to_s.downcase.split(/\s+/)
          rel_tokens.include?("icon") || rel_tokens.include?("apple-touch-icon")
        end

        href = link&.[]("href")
        icon_uri = href.present? ? URI.join(base_uri, href) : URI.join(base_uri, "/favicon.ico")

        return nil unless icon_uri.is_a?(URI::HTTP)
        return nil if icon_uri.to_s.length > 2048

        icon_uri.to_s
      rescue URI::InvalidURIError, ArgumentError
        nil
      end

      def text_of(value)
        text = value.to_s.strip
        text.presence
      end

      def ip_literal?(host)
        IPAddr.new(host.delete_prefix("[").delete_suffix("]"))
        true
      rescue IPAddr::InvalidAddressError
        false
      end
  end
end
