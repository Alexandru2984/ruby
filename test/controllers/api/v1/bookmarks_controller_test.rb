require "test_helper"

module Api
  module V1
    class BookmarksControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @user.regenerate_api_token
        @headers = { "Authorization" => "Bearer #{@user.api_token}" }
      end

      test "rejects requests without a token" do
        get api_v1_bookmarks_url, as: :json
        assert_response :unauthorized
        assert_equal "Unauthorized", response.parsed_body["error"]
      end

      test "rejects requests with a bogus token" do
        get api_v1_bookmarks_url, headers: { "Authorization" => "Bearer wrong" }, as: :json
        assert_response :unauthorized
      end

      test "index returns only the current user's bookmarks with pagination info" do
        get api_v1_bookmarks_url, headers: @headers, as: :json
        assert_response :success

        body = response.parsed_body
        urls = body["bookmarks"].map { |b| b["url"] }
        assert_includes urls, bookmarks(:one).url
        assert_not_includes urls, bookmarks(:two).url
        assert_equal 1, body["page"]
        assert body.key?("count")
      end

      test "index supports search and tag filters" do
        @user.bookmarks.create!(url: "https://example.com/elixir", title: "Elixir School", tag_list: "elixir")

        get api_v1_bookmarks_url(q: "elixir"), headers: @headers, as: :json
        assert_equal 1, response.parsed_body["bookmarks"].size

        get api_v1_bookmarks_url(tag: "elixir"), headers: @headers, as: :json
        assert_equal 1, response.parsed_body["bookmarks"].size

        get api_v1_bookmarks_url(q: "no-such-thing"), headers: @headers, as: :json
        assert_equal 0, response.parsed_body["bookmarks"].size
      end

      test "show returns a bookmark and 404s on foreign ones" do
        get api_v1_bookmark_url(bookmarks(:one)), headers: @headers, as: :json
        assert_response :success
        assert_equal bookmarks(:one).url, response.parsed_body["url"]

        get api_v1_bookmark_url(bookmarks(:two)), headers: @headers, as: :json
        assert_response :not_found
      end

      test "create saves a bookmark with tags" do
        assert_difference("@user.bookmarks.count") do
          post api_v1_bookmarks_url, headers: @headers,
               params: { bookmark: { url: "api-created.example.com", tag_list: "api, test" } }, as: :json
        end

        assert_response :created
        body = response.parsed_body
        assert_equal "https://api-created.example.com", body["url"]
        assert_equal %w[api test], body["tags"]
      end

      test "create rejects invalid urls with error details" do
        assert_no_difference("Bookmark.count") do
          post api_v1_bookmarks_url, headers: @headers,
               params: { bookmark: { url: "javascript:alert(1)" } }, as: :json
        end

        assert_response :unprocessable_entity
        assert response.parsed_body["errors"].any?
      end

      test "destroy deletes own bookmarks only" do
        assert_difference("Bookmark.count", -1) do
          delete api_v1_bookmark_url(bookmarks(:one)), headers: @headers, as: :json
        end
        assert_response :no_content

        assert_no_difference("Bookmark.count") do
          delete api_v1_bookmark_url(bookmarks(:two)), headers: @headers, as: :json
        end
        assert_response :not_found
      end

      test "revoked token stops working" do
        @user.update!(api_token: nil)

        get api_v1_bookmarks_url, headers: @headers, as: :json
        assert_response :unauthorized
      end
    end
  end
end
