class AddLinkStatusToBookmarks < ActiveRecord::Migration[8.1]
  def change
    add_column :bookmarks, :link_status, :string
    add_column :bookmarks, :link_checked_at, :datetime
  end
end
