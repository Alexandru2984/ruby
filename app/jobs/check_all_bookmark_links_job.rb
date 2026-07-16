# Fans out a link check per active bookmark. Scheduled daily via
# config/recurring.yml; archived bookmarks are left alone.
class CheckAllBookmarkLinksJob < ApplicationJob
  queue_as :default

  def perform
    Bookmark.active.find_each do |bookmark|
      CheckBookmarkLinkJob.perform_later(bookmark)
    end
  end
end
