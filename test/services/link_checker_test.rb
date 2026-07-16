require "test_helper"

class LinkCheckerTest < ActiveSupport::TestCase
  # Replaces the private HTTP request with canned responses per verb class.
  def with_responses(responses)
    LinkChecker.singleton_class.alias_method :__original_request, :request
    LinkChecker.define_singleton_method(:request) { |_uri, verb| responses.fetch(verb) }
    yield
  ensure
    LinkChecker.singleton_class.alias_method :request, :__original_request
    LinkChecker.singleton_class.remove_method :__original_request
  end

  test "2xx responses are ok" do
    with_responses(Net::HTTP::Head => Net::HTTPOK.new("1.1", "200", "OK")) do
      result = LinkChecker.check("https://example.com/page")
      assert result.ok?
      assert_equal 200, result.code
    end
  end

  test "redirects and auth walls count as alive" do
    [ Net::HTTPMovedPermanently.new("1.1", "301", "Moved"), Net::HTTPForbidden.new("1.1", "403", "Forbidden"), Net::HTTPTooManyRequests.new("1.1", "429", "Slow down") ].each do |response|
      with_responses(Net::HTTP::Head => response) do
        assert LinkChecker.check("https://example.com").ok?, "expected #{response.code} to be alive"
      end
    end
  end

  test "404 and 500 are broken with the code recorded" do
    with_responses(Net::HTTP::Head => Net::HTTPNotFound.new("1.1", "404", "Not Found")) do
      result = LinkChecker.check("https://example.com/gone")
      assert_not result.ok?
      assert_equal 404, result.code
    end

    with_responses(Net::HTTP::Head => Net::HTTPInternalServerError.new("1.1", "500", "Boom")) do
      assert_not LinkChecker.check("https://example.com").ok?
    end
  end

  test "falls back to GET when HEAD is not allowed" do
    responses = {
      Net::HTTP::Head => Net::HTTPMethodNotAllowed.new("1.1", "405", "Nope"),
      Net::HTTP::Get => Net::HTTPOK.new("1.1", "200", "OK")
    }

    with_responses(responses) do
      result = LinkChecker.check("https://example.com/head-hater")
      assert result.ok?
      assert_equal 200, result.code
    end
  end

  test "blocked hosts are broken without any request" do
    with_responses(Hash.new { raise "no request expected" }) do
      assert_not LinkChecker.check("http://127.0.0.1/admin").ok?
      assert_not LinkChecker.check("http://192.168.1.1/router").ok?
    end
  end

  test "garbage urls are broken" do
    assert_not LinkChecker.check("not a url").ok?
  end
end
