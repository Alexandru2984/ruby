class CheckBookmarkLinkJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(bookmark)
    result = LinkChecker.check(bookmark.url)
    bookmark.update_columns(link_status: result.status, link_checked_at: Time.current)
  end
end
