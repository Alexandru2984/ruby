require "application_system_test_case"

class BookmarkFlowsTest < ApplicationSystemTestCase
  test "signing up, saving, searching and favoriting a bookmark" do
    visit root_url

    # Redirected to sign in; head to sign up instead.
    click_on "Sign up", match: :first
    fill_in "Email address", with: "system@example.com"
    fill_in "Password", with: "systempass123", match: :prefer_exact
    fill_in "Password confirmation", with: "systempass123"
    click_on "Create account"

    assert_text "Save your first bookmark"

    # Save a bookmark with tags.
    click_on "New bookmark", match: :first
    fill_in "Url", with: "https://guides.rubyonrails.org/testing.html"
    fill_in "Title", with: "Testing Rails Applications"
    fill_in "Tags", with: "rails, testing"
    click_on "Create Bookmark"

    assert_text "Bookmark was successfully created"

    # It shows up on the index with its tags.
    click_on "Bookmarks", match: :first
    assert_text "Testing Rails Applications"
    assert_link "rails"
    assert_link "testing"

    # Search finds it; a bogus search does not.
    fill_in "q", with: "testing rails"
    click_on "Search"
    assert_text "Testing Rails Applications"

    fill_in "q", with: "definitely-not-there"
    click_on "Search"
    assert_text "Nothing matches those filters"

    # Favorite it and find it under the Favorites filter.
    click_on "Clear filters"
    find("button[title='Add to favorites']").click
    click_on "Favorites"
    assert_text "Testing Rails Applications"
  end

  test "signing in with wrong credentials shows an alert" do
    visit new_session_url

    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "wrong-password"
    click_button "Sign in"

    assert_text "Try another email address or password"
  end
end
