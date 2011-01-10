class AddBigcIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :bigc_id, :string
  end

  def self.down
    remove_column :users, :bigc_id
  end
end
