class FetchBookmarkMetadataJob < ApplicationJob
  queue_as :default

  retry_on UrlMetadata::FetchError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(bookmark)
    metadata = UrlMetadata.fetch(bookmark.url)
    return if metadata.nil?

    bookmark.title = metadata.title.truncate(255) if bookmark.title.blank? && metadata.title.present?
    bookmark.description = metadata.description.truncate(2000) if bookmark.description.blank? && metadata.description.present?
    bookmark.favicon_url = metadata.favicon_url if metadata.favicon_url.present?

    bookmark.save! if bookmark.changed?
  end
end
