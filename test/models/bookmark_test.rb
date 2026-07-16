require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid with url and user" do
    bookmark = @user.bookmarks.new(url: "https://example.com/article")
    assert bookmark.valid?
  end

  test "requires a url" do
    bookmark = @user.bookmarks.new(url: "")
    assert_not bookmark.valid?
    assert bookmark.errors[:url].any?
  end

  test "requires url to belong to a user" do
    bookmark = Bookmark.new(url: "https://example.com")
    assert_not bookmark.valid?
    assert bookmark.errors[:user].any?
  end

  test "prepends https scheme when missing" do
    bookmark = @user.bookmarks.create!(url: "example.com/page")
    assert_equal "https://example.com/page", bookmark.url
  end

  test "downcases scheme and host but preserves path case" do
    bookmark = @user.bookmarks.create!(url: "HTTPS://EXAMPLE.com/CaseSensitive/Path")
    assert_equal "https://example.com/CaseSensitive/Path", bookmark.url
  end

  test "strips surrounding whitespace from url" do
    bookmark = @user.bookmarks.create!(url: "  https://example.com  ")
    assert_equal "https://example.com", bookmark.url
  end

  test "rejects non-http schemes" do
    %w[ftp://example.com javascript:alert(1) file:///etc/passwd].each do |bad|
      bookmark = @user.bookmarks.new(url: bad)
      assert_not bookmark.valid?, "expected #{bad.inspect} to be invalid"
    end
  end

  test "rejects duplicate url for the same user" do
    duplicate = @user.bookmarks.new(url: bookmarks(:one).url)
    assert_not duplicate.valid?
  end

  test "allows the same url for different users" do
    bookmark = users(:two).bookmarks.new(url: bookmarks(:one).url)
    assert bookmark.valid?
  end

  test "display_title falls back to host when title is blank" do
    bookmark = @user.bookmarks.new(url: "https://example.com/deep/path")
    assert_equal "example.com", bookmark.display_title

    bookmark.title = "Named"
    assert_equal "Named", bookmark.display_title
  end
end
