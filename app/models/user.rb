class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token
  has_many :sessions, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :tags, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

  # Public sharing is opt-in: no token means nothing is exposed.
  def sharing_enabled?
    public_token.present?
  end

  def enable_public_sharing!
    update!(public_token: self.class.generate_unique_secure_token)
  end

  def disable_public_sharing!
    update!(public_token: nil)
  end
end
