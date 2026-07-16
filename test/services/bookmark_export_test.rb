require "test_helper"

class BookmarkExportTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @bookmark = bookmarks(:one)
    @bookmark.update!(tag_list: "ruby, docs")
    @bookmarks = @user.bookmarks.includes(:tags)
  end

  test "to_json includes the bookmark fields and tags" do
    parsed = JSON.parse(BookmarkExport.to_json(@bookmarks))

    entry = parsed.find { |row| row["url"] == @bookmark.url }
    assert_equal "Rails Guides", entry["title"]
    assert_equal %w[docs ruby], entry["tags"]
    assert_equal false, entry["favorite"]
  end

  test "to_csv produces a header row plus one row per bookmark" do
    csv = CSV.parse(BookmarkExport.to_csv(@bookmarks), headers: true)

    assert_equal %w[title url description tags favorite archived visits created_at], csv.headers
    assert_equal @bookmarks.count, csv.size
    assert_includes csv.map { |row| row["url"] }, @bookmark.url
  end

  test "to_netscape_html round-trips through BookmarkImport" do
    html = BookmarkExport.to_netscape_html(@bookmarks)
    assert_includes html, "<!DOCTYPE NETSCAPE-Bookmark-file-1>"
    assert_includes html, @bookmark.url

    other_user = users(:two)
    result = BookmarkImport.call(user: other_user, html: html)

    assert_equal @bookmarks.count, result.imported
    reimported = other_user.bookmarks.find_by!(url: @bookmark.url)
    assert_equal @bookmark.title, reimported.title
    assert_equal %w[docs ruby], reimported.tags.map(&:name).sort
  end

  test "to_netscape_html escapes html in titles" do
    @bookmark.update!(title: %(<script>alert("x")</script>))
    html = BookmarkExport.to_netscape_html(@bookmarks.reload)

    assert_not_includes html, "<script>alert"
    assert_includes html, "&lt;script&gt;"
  end
end
