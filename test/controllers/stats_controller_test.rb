require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "requires authentication" do
    sign_out

    get stats_url
    assert_redirected_to new_session_url
  end

  test "shows totals for the current user only" do
    @user.bookmarks.create!(url: "https://example.com/fav", favorite: true)
    @user.bookmarks.create!(url: "https://example.com/gone", archived_at: Time.current)
    users(:two).bookmarks.create!(url: "https://example.com/foreign", favorite: true)

    get stats_url
    assert_response :success

    assert_select "p", text: "3" do |elements|
      assert elements.any?, "expected a bookmarks total of 3"
    end
    assert_select "a[href=?]", bookmarks_path(filter: "favorites"), text: "Favorites"
    assert_select "a[href=?]", bookmarks_path(filter: "broken")
  end

  test "shows top tags and most visited" do
    tagged = @user.bookmarks.create!(url: "https://example.com/tagged", tag_list: "ruby")
    tagged.register_visit!

    get stats_url
    assert_select "a[href=?]", bookmarks_path(tag: "ruby")
    assert_select "a[href=?]", visit_bookmark_path(tagged)
  end

  test "renders monthly chart including empty months" do
    travel_to Time.zone.local(2026, 7, 15, 12) do
      @user.bookmarks.create!(url: "https://example.com/recent")
      old = @user.bookmarks.create!(url: "https://example.com/older")
      old.update_columns(created_at: 2.months.ago)

      get stats_url
      assert_response :success
      assert_select "details table tbody tr", count: 6
    end
  end
end
