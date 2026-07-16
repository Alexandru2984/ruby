require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "normalizes name" do
    tag = @user.tags.create!(name: "  Ruby   On  Rails ")
    assert_equal "ruby on rails", tag.name
  end

  test "requires unique name per user" do
    @user.tags.create!(name: "ruby")
    assert_not @user.tags.new(name: "Ruby").valid?
    assert users(:two).tags.new(name: "ruby").valid?
  end

  test "prune_orphaned removes tags without taggings" do
    orphan = @user.tags.create!(name: "orphan")
    used = @user.tags.create!(name: "used")
    bookmarks(:one).tags << used

    Tag.prune_orphaned(@user)

    assert_not Tag.exists?(orphan.id)
    assert Tag.exists?(used.id)
  end
end
