class Tagging < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :bookmark_id }
end
