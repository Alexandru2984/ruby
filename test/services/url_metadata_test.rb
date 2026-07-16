require "test_helper"

class UrlMetadataTest < ActiveSupport::TestCase
  BASE_URI = URI.parse("https://example.com/article")

  test "parse extracts og tags first" do
    html = <<~HTML
      <html><head>
        <title>Plain title</title>
        <meta property="og:title" content="OG title">
        <meta name="description" content="Plain description">
        <meta property="og:description" content="OG description">
      </head></html>
    HTML

    result = UrlMetadata.parse(html, BASE_URI)
    assert_equal "OG title", result.title
    assert_equal "OG description", result.description
  end

  test "parse falls back to title tag and meta description" do
    html = <<~HTML
      <html><head>
        <title>  Plain title  </title>
        <meta name="description" content="Plain description">
      </head></html>
    HTML

    result = UrlMetadata.parse(html, BASE_URI)
    assert_equal "Plain title", result.title
    assert_equal "Plain description", result.description
  end

  test "parse absolutizes the favicon link" do
    html = %(<html><head><link rel="icon" href="/assets/icon.png"></head></html>)

    result = UrlMetadata.parse(html, BASE_URI)
    assert_equal "https://example.com/assets/icon.png", result.favicon_url
  end

  test "parse defaults the favicon to /favicon.ico" do
    result = UrlMetadata.parse("<html></html>", BASE_URI)
    assert_equal "https://example.com/favicon.ico", result.favicon_url
  end

  test "blocked_host? refuses private, loopback and link-local addresses" do
    %w[127.0.0.1 10.1.2.3 192.168.1.1 172.16.0.1 169.254.1.1 ::1].each do |ip|
      assert UrlMetadata.blocked_host?(ip), "expected #{ip} to be blocked"
    end
  end

  test "blocked_host? refuses hosts that resolve to loopback" do
    assert UrlMetadata.blocked_host?("localhost")
  end

  test "blocked_host? refuses blank and unresolvable hosts" do
    assert UrlMetadata.blocked_host?("")
    assert UrlMetadata.blocked_host?(nil)
  end

  test "blocked_host? allows public addresses" do
    assert_not UrlMetadata.blocked_host?("1.1.1.1")
  end

  test "fetch refuses urls with blocked hosts without any http call" do
    assert_nil UrlMetadata.fetch("http://127.0.0.1/admin")
    assert_nil UrlMetadata.fetch("http://192.168.0.1:8080/router")
  end
end
