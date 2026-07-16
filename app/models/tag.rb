class Tag < ApplicationRecord
  NAME_MAX_LENGTH = 40

  belongs_to :user
  has_many :taggings, dependent: :destroy
  has_many :bookmarks, through: :taggings

  normalizes :name, with: ->(name) { name.strip.downcase.squeeze(" ") }

  validates :name, presence: true,
                   length: { maximum: NAME_MAX_LENGTH },
                   uniqueness: { scope: :user_id }

  scope :alphabetical, -> { order(:name) }

  # Removes tags that no longer label any bookmark.
  def self.prune_orphaned(user)
    user.tags.where.missing(:taggings).delete_all
  end
end
