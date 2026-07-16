require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "requires authentication" do
    sign_out

    get new_import_url
    assert_redirected_to new_session_url
  end

  test "should get new" do
    get new_import_url
    assert_response :success
  end

  test "imports an uploaded bookmarks file" do
    assert_difference("users(:one).bookmarks.count", 2) do
      post import_url, params: { file: fixture_file_upload("netscape_bookmarks.html", "text/html") }
    end

    assert_redirected_to bookmarks_url
    follow_redirect!
    assert_select "#notice", /Imported 2 bookmarks, skipped 1/
  end

  test "rejects a missing file" do
    assert_no_difference("Bookmark.count") do
      post import_url
    end

    assert_redirected_to new_import_url
  end
end
