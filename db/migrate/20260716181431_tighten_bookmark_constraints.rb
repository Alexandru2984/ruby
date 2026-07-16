class TightenBookmarkConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :bookmarks, :url, false
    add_index :bookmarks, [ :user_id, :url ], unique: true
    add_index :bookmarks, [ :user_id, :created_at ]
  end
end
