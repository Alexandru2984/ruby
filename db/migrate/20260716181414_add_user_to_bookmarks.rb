class AddUserToBookmarks < ActiveRecord::Migration[8.1]
  # Lightweight table-backed classes so the migration never depends on
  # application models (which may change or disappear later).
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationBookmark < ActiveRecord::Base
    self.table_name = "bookmarks"
  end

  def up
    add_reference :bookmarks, :user, foreign_key: true

    if MigrationBookmark.where(user_id: nil).exists?
      owner = MigrationUser.first || MigrationUser.create!(
        email_address: "legacy-owner@localhost",
        password_digest: BCrypt::Password.create(SecureRandom.base58(32))
      )
      MigrationBookmark.where(user_id: nil).update_all(user_id: owner.id)
    end

    change_column_null :bookmarks, :user_id, false
  end

  def down
    remove_reference :bookmarks, :user
  end
end
