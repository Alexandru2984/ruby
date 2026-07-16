class AddFaviconUrlToBookmarks < ActiveRecord::Migration[8.1]
  def change
    add_column :bookmarks, :favicon_url, :string
  end
end
