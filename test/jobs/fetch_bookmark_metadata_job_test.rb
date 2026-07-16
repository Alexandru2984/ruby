require "test_helper"

class FetchBookmarkMetadataJobTest < ActiveJob::TestCase
  setup do
    @bookmark = users(:one).bookmarks.create!(url: "https://example.com/post")
  end

  # Replaces UrlMetadata.fetch with a canned result for the block's duration.
  def with_fetched_metadata(result)
    UrlMetadata.singleton_class.alias_method :__original_fetch, :fetch
    UrlMetadata.define_singleton_method(:fetch) { |_url| result }
    yield
  ensure
    UrlMetadata.singleton_class.alias_method :fetch, :__original_fetch
    UrlMetadata.singleton_class.remove_method :__original_fetch
  end

  test "creating a bookmark enqueues a metadata fetch" do
    assert_enqueued_with(job: FetchBookmarkMetadataJob) do
      users(:one).bookmarks.create!(url: "https://example.com/another")
    end
  end

  test "fills in blank title, description and favicon" do
    result = UrlMetadata::Result.new(title: "Fetched title", description: "Fetched description", favicon_url: "https://example.com/favicon.ico")

    with_fetched_metadata(result) do
      FetchBookmarkMetadataJob.perform_now(@bookmark)
    end

    @bookmark.reload
    assert_equal "Fetched title", @bookmark.title
    assert_equal "Fetched description", @bookmark.description
    assert_equal "https://example.com/favicon.ico", @bookmark.favicon_url
  end

  test "does not overwrite a user-provided title or description" do
    @bookmark.update!(title: "Mine", description: "My notes")
    result = UrlMetadata::Result.new(title: "Fetched", description: "Fetched", favicon_url: nil)

    with_fetched_metadata(result) do
      FetchBookmarkMetadataJob.perform_now(@bookmark)
    end

    @bookmark.reload
    assert_equal "Mine", @bookmark.title
    assert_equal "My notes", @bookmark.description
  end

  test "leaves the bookmark untouched when nothing could be fetched" do
    with_fetched_metadata(nil) do
      assert_no_changes -> { @bookmark.reload.attributes } do
        FetchBookmarkMetadataJob.perform_now(@bookmark)
      end
    end
  end

  test "truncates oversized fetched values to fit validations" do
    result = UrlMetadata::Result.new(title: "x" * 500, description: "y" * 5000, favicon_url: nil)

    with_fetched_metadata(result) do
      FetchBookmarkMetadataJob.perform_now(@bookmark)
    end

    @bookmark.reload
    assert_equal 255, @bookmark.title.length
    assert_equal 2000, @bookmark.description.length
  end
end
