class Bookmark < ApplicationRecord
  belongs_to :user

  normalizes :url, with: ->(url) {
    url = url.strip

    begin
      url = "https://#{url}" if url.present? && URI.parse(url).scheme.nil?

      uri = URI.parse(url)
      uri.scheme = uri.scheme&.downcase
      uri.host = uri.host&.downcase
      uri.to_s
    rescue URI::InvalidURIError
      url
    end
  }

  validates :url, presence: true, length: { maximum: 2048 },
                  uniqueness: { scope: :user_id, message: "has already been bookmarked" }
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 2000 }
  validate :url_must_be_http

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # What to show when the page title hasn't been set (yet).
  def display_title
    title.presence || host || url
  end

  def host
    URI.parse(url.to_s).host
  rescue URI::InvalidURIError
    nil
  end

  private
    def url_must_be_http
      return if url.blank?

      uri = URI.parse(url)
      errors.add(:url, "must be a valid HTTP or HTTPS address") unless uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      errors.add(:url, "must be a valid HTTP or HTTPS address")
    end
end
