require "test_helper"

class BookmarkImportTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @html = file_fixture("netscape_bookmarks.html").read
  end

  test "imports valid entries with titles, tags, descriptions and original dates" do
    result = nil
    assert_difference("@user.bookmarks.count", 2) do
      result = BookmarkImport.call(user: @user, html: @html)
    end

    assert_equal 2, result.imported
    assert_equal 1, result.skipped

    imported = @user.bookmarks.find_by!(url: "https://imported-one.example.com/")
    assert_equal "Imported One", imported.title
    assert_equal "First imported bookmark", imported.description
    assert_equal %w[imported reading], imported.tags.map(&:name).sort
    assert_equal Time.zone.at(1_700_000_000), imported.created_at
  end

  test "skips duplicates on re-import" do
    BookmarkImport.call(user: @user, html: @html)

    assert_no_difference("@user.bookmarks.count") do
      result = BookmarkImport.call(user: @user, html: @html)
      assert_equal 0, result.imported
    end
  end

  test "ignores non-http links entirely" do
    BookmarkImport.call(user: @user, html: @html)
    assert_not @user.bookmarks.exists?(url: "ftp://bad.example.com/")
  end

  test "handles files with no links" do
    result = BookmarkImport.call(user: @user, html: "<html><body>nothing here</body></html>")
    assert_equal 0, result.imported
    assert_equal 0, result.skipped
  end
end
