class AddPublicTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :public_token, :string
    add_index :users, :public_token, unique: true
  end
end
