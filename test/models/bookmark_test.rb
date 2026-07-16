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

  test "assigns tags from a comma-separated tag_list" do
    bookmark = @user.bookmarks.create!(url: "https://example.com/tagged", tag_list: "Ruby, rails,  Ruby ")
    assert_equal %w[rails ruby], bookmark.tags.map(&:name).sort
  end

  test "reuses existing tags instead of duplicating them" do
    existing = @user.tags.create!(name: "ruby")
    bookmark = @user.bookmarks.create!(url: "https://example.com/reuse", tag_list: "ruby")
    assert_equal [ existing.id ], bookmark.tag_ids
  end

  test "replacing tag_list prunes tags that are no longer used" do
    bookmark = @user.bookmarks.create!(url: "https://example.com/prune", tag_list: "old-tag")
    bookmark.update!(tag_list: "new-tag")

    assert_equal %w[new-tag], bookmark.reload.tags.map(&:name)
    assert_not @user.tags.exists?(name: "old-tag")
  end

  test "rejects more than MAX_TAGS tags" do
    list = (1..Bookmark::MAX_TAGS + 1).map { |i| "tag#{i}" }.join(",")
    bookmark = @user.bookmarks.new(url: "https://example.com/too-many", tag_list: list)
    assert_not bookmark.valid?
    assert bookmark.errors[:tag_list].any?
  end

  test "tagged_with matches normalized tag names" do
    bookmark = @user.bookmarks.create!(url: "https://example.com/find-me", tag_list: "ruby")
    assert_includes @user.bookmarks.tagged_with(" Ruby "), bookmark
    assert_empty @user.bookmarks.tagged_with("missing")
  end

  test "register_visit! increments visits without touching updated_at" do
    bookmark = bookmarks(:one)
    original_updated_at = bookmark.updated_at

    bookmark.register_visit!
    bookmark.reload

    assert_equal 1, bookmark.visits_count
    assert_not_nil bookmark.last_visited_at
    assert_equal original_updated_at.to_i, bookmark.updated_at.to_i
  end

  test "archive! and unarchive! toggle archived state" do
    bookmark = bookmarks(:one)
    assert_not bookmark.archived?

    bookmark.archive!
    assert bookmark.archived?
    assert_includes Bookmark.archived, bookmark
    assert_not_includes Bookmark.active, bookmark

    bookmark.unarchive!
    assert_not bookmark.archived?
  end

  test "display_title falls back to host when title is blank" do
    bookmark = @user.bookmarks.new(url: "https://example.com/deep/path")
    assert_equal "example.com", bookmark.display_title

    bookmark.title = "Named"
    assert_equal "Named", bookmark.display_title
  end
end
