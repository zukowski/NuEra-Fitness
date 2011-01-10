class ConvertUserBigcIdField < ActiveRecord::Migration
  def self.up
    remove_column :users, :bigc_id
    add_column :users, :bigc_id, :integer
  end

  def self.down
    remove_column :users, :bigc_id
    add_column :users, :bigc_id, :string
  end
end
