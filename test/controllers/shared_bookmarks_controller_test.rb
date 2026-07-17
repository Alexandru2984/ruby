require "test_helper"

class SharedBookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @owner.enable_public_sharing!
    @favorite = @owner.bookmarks.create!(url: "https://example.com/shared-fav", title: "Shared Favorite", favorite: true)
  end

  test "shows the owner's favorites without authentication" do
    get shared_bookmarks_url(token: @owner.public_token)

    assert_response :success
    assert_select "h2", /Shared Favorite/
    assert_select "a[href=?]", @favorite.url
  end

  test "hides non-favorites, archived favorites and other users' bookmarks" do
    archived_favorite = @owner.bookmarks.create!(url: "https://example.com/archived-fav", favorite: true, archived_at: Time.current)

    get shared_bookmarks_url(token: @owner.public_token)

    assert_select "a[href=?]", bookmarks(:one).url, count: 0
    assert_select "a[href=?]", archived_favorite.url, count: 0
    assert_select "a[href=?]", bookmarks(:two).url, count: 0
  end

  test "offers no edit or bulk controls" do
    get shared_bookmarks_url(token: @owner.public_token)

    assert_select "a[href=?]", edit_bookmark_path(@favorite), count: 0
    assert_select "input[type=checkbox]", count: 0
  end

  test "404s for unknown tokens" do
    get shared_bookmarks_url(token: "nope")
    assert_response :not_found
  end

  test "serves an rss feed of the shared favorites" do
    get shared_bookmarks_url(token: @owner.public_token, format: :rss)

    assert_response :success
    assert_match %r{application/rss\+xml}, response.content_type
    assert_includes response.body, "<title>Shared Favorite</title>"
    assert_includes response.body, "<link>#{@favorite.url}</link>"
    assert_not_includes response.body, bookmarks(:one).url
  end

  test "rss 404s for unknown tokens" do
    get shared_bookmarks_url(token: "nope", format: :rss)
    assert_response :not_found
  end

  test "html page advertises the rss feed" do
    get shared_bookmarks_url(token: @owner.public_token)
    assert_select "link[type='application/rss+xml']"
  end

  test "disabled sharing kills the link" do
    token = @owner.public_token
    @owner.disable_public_sharing!

    get shared_bookmarks_url(token: token)
    assert_response :not_found
  end
end

class PublicSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "create enables sharing and rotates on repeat" do
    post public_share_url
    first_token = users(:one).reload.public_token
    assert first_token.present?

    post public_share_url
    assert_not_equal first_token, users(:one).reload.public_token
  end

  test "destroy disables sharing" do
    users(:one).enable_public_sharing!

    delete public_share_url
    assert_nil users(:one).reload.public_token
  end
end
