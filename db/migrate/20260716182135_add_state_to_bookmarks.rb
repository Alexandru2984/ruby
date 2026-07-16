class AddStateToBookmarks < ActiveRecord::Migration[8.1]
  def change
    add_column :bookmarks, :favorite, :boolean, default: false, null: false
    add_column :bookmarks, :archived_at, :datetime
    add_column :bookmarks, :visits_count, :integer, default: 0, null: false
    add_column :bookmarks, :last_visited_at, :datetime
  end
end
