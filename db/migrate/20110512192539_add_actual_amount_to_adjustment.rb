class AddActualAmountToAdjustment < ActiveRecord::Migration
  def self.up
    add_column :adjustments, :actual_amount, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    remove_column :adjustments, :actual_amount
  end
end
