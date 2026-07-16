class Bookmark < ApplicationRecord
  MAX_TAGS = 20

  belongs_to :user
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

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
  validate :tag_list_within_limits

  before_save :apply_tag_list
  after_commit -> { Tag.prune_orphaned(user) }, on: %i[ update destroy ]
  after_create_commit :fetch_metadata_later

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :tagged_with, ->(name) { joins(:tags).where(tags: { name: Tag.normalize_value_for(:name, name.to_s) }) }
  scope :favorites, -> { where(favorite: true) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :broken, -> { where(link_status: "broken") }

  SORTS = %w[newest oldest title most_visited].freeze

  # Case-insensitive substring match across title, url and description.
  def self.search(query)
    q = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where("bookmarks.title LIKE :q ESCAPE '\\' OR bookmarks.url LIKE :q ESCAPE '\\' OR bookmarks.description LIKE :q ESCAPE '\\'", q: q)
  end

  def self.sorted_by(key)
    case key
    when "oldest"       then order(created_at: :asc, id: :asc)
    when "title"        then order(Arel.sql("title COLLATE NOCASE ASC"), id: :asc)
    when "most_visited" then order(visits_count: :desc, id: :desc)
    else newest_first
    end
  end

  def archived?
    archived_at.present?
  end

  def link_broken?
    link_status == "broken"
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  # Counts a click-through without bumping updated_at; atomic in SQL so
  # concurrent visits don't lose increments.
  def register_visit!
    self.class.where(id: id).update_all([ "visits_count = visits_count + 1, last_visited_at = ?", Time.current ])
  end

  # Comma-separated tag names, used as a virtual form attribute.
  def tag_list
    @tag_list || tags.sort_by(&:name).map(&:name).join(", ")
  end

  def tag_list=(value)
    @tag_list = value
  end

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
    def parsed_tag_names
      @tag_list.to_s.split(",").map { |name| Tag.normalize_value_for(:name, name) }.reject(&:blank?).uniq
    end

    def tag_list_within_limits
      return if @tag_list.nil?

      names = parsed_tag_names
      errors.add(:tag_list, "can have at most #{MAX_TAGS} tags") if names.size > MAX_TAGS
      errors.add(:tag_list, "tags must be #{Tag::NAME_MAX_LENGTH} characters or fewer") if names.any? { |name| name.length > Tag::NAME_MAX_LENGTH }
    end

    def apply_tag_list
      return if @tag_list.nil?

      self.tags = parsed_tag_names.map { |name| user.tags.find_or_create_by!(name: name) }
      @tag_list = nil
    end

    def fetch_metadata_later
      FetchBookmarkMetadataJob.perform_later(self)
    end

    def url_must_be_http
      return if url.blank?

      uri = URI.parse(url)
      errors.add(:url, "must be a valid HTTP or HTTPS address") unless uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      errors.add(:url, "must be a valid HTTP or HTTPS address")
    end
end
