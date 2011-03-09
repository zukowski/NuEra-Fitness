class Supplier < ActiveRecord::Migration
  def self.up
    create_table :suppliers do |t|
      t.string :name
      t.string :city
      t.string :state
      t.string :country
      t.string :zip
      t.integer :handling_fee
    end
  end

  def self.down
    drop_table :suppliers
  end
end
