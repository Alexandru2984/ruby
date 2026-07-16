require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bookmark = bookmarks(:one)
    sign_in_as users(:one)
  end

  test "redirects to sign in when unauthenticated" do
    sign_out

    get bookmarks_url
    assert_redirected_to new_session_url
  end

  test "should get index" do
    get bookmarks_url
    assert_response :success
  end

  test "should get new" do
    get new_bookmark_url
    assert_response :success
  end

  test "should create bookmark owned by current user" do
    assert_difference("users(:one).bookmarks.count") do
      post bookmarks_url, params: { bookmark: { description: "A brand new find", title: "New", url: "https://example.com/fresh" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal users(:one), Bookmark.last.user
  end

  test "does not create bookmark with invalid url" do
    assert_no_difference("Bookmark.count") do
      post bookmarks_url, params: { bookmark: { url: "javascript:alert(1)" } }
    end

    assert_response :unprocessable_entity
  end

  test "should show bookmark" do
    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should get edit" do
    get edit_bookmark_url(@bookmark)
    assert_response :success
  end

  test "should update bookmark" do
    patch bookmark_url(@bookmark), params: { bookmark: { description: @bookmark.description, title: @bookmark.title, url: @bookmark.url } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should destroy bookmark" do
    assert_difference("Bookmark.count", -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to bookmarks_url
  end

  test "visit counts the click-through and redirects to the target url" do
    assert_changes -> { @bookmark.reload.visits_count }, from: 0, to: 1 do
      get visit_bookmark_url(@bookmark)
    end

    assert_redirected_to @bookmark.url
    assert_not_nil @bookmark.reload.last_visited_at
  end

  test "toggle_favorite flips the favorite flag" do
    patch toggle_favorite_bookmark_url(@bookmark)
    assert @bookmark.reload.favorite?

    patch toggle_favorite_bookmark_url(@bookmark)
    assert_not @bookmark.reload.favorite?
  end

  test "archive hides and unarchive restores a bookmark" do
    patch archive_bookmark_url(@bookmark)
    assert @bookmark.reload.archived?

    patch unarchive_bookmark_url(@bookmark)
    assert_not @bookmark.reload.archived?
  end

  test "cannot visit another user's bookmark" do
    get visit_bookmark_url(bookmarks(:two))
    assert_response :not_found
  end

  test "cannot see another user's bookmark" do
    get bookmark_url(bookmarks(:two))
    assert_response :not_found
  end

  test "cannot update another user's bookmark" do
    patch bookmark_url(bookmarks(:two)), params: { bookmark: { title: "hijacked" } }
    assert_response :not_found
    assert_equal "Hotwire", bookmarks(:two).reload.title
  end

  test "cannot destroy another user's bookmark" do
    assert_no_difference("Bookmark.count") do
      delete bookmark_url(bookmarks(:two))
    end
    assert_response :not_found
  end

  test "index filters by tag" do
    tagged = users(:one).bookmarks.create!(url: "https://example.com/tagged", tag_list: "ruby")

    get bookmarks_url(tag: "ruby")
    assert_response :success
    assert_select "a[href=?]", bookmark_path(tagged)
    assert_select "a[href=?]", bookmark_path(bookmarks(:one)), count: 0
  end

  test "index only lists current user's bookmarks" do
    get bookmarks_url
    assert_response :success
    assert_select "a[href=?]", bookmark_path(bookmarks(:one))
    assert_select "a[href=?]", bookmark_path(bookmarks(:two)), count: 0
  end
end
