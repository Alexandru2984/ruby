require "test_helper"

class CheckBookmarkLinkJobTest < ActiveJob::TestCase
  def with_check_result(result)
    LinkChecker.singleton_class.alias_method :__original_check, :check
    LinkChecker.define_singleton_method(:check) { |_url| result }
    yield
  ensure
    LinkChecker.singleton_class.alias_method :check, :__original_check
    LinkChecker.singleton_class.remove_method :__original_check
  end

  test "records a broken link" do
    bookmark = bookmarks(:one)

    with_check_result(LinkChecker::Result.new(status: "broken", code: 404)) do
      CheckBookmarkLinkJob.perform_now(bookmark)
    end

    bookmark.reload
    assert bookmark.link_broken?
    assert_not_nil bookmark.link_checked_at
  end

  test "records a healthy link and clears prior broken state" do
    bookmark = bookmarks(:one)
    bookmark.update_columns(link_status: "broken")

    with_check_result(LinkChecker::Result.new(status: "ok", code: 200)) do
      CheckBookmarkLinkJob.perform_now(bookmark)
    end

    assert_not bookmark.reload.link_broken?
  end

  test "fan-out job enqueues one check per active bookmark" do
    bookmarks(:two).archive!

    assert_enqueued_jobs Bookmark.active.count, only: CheckBookmarkLinkJob do
      CheckAllBookmarkLinksJob.perform_now
    end
  end
end
