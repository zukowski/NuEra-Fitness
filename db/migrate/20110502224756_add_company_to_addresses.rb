class AddCompanyToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :company, :string
  end

  def self.down
    remove_column :addresses, :company
  end
end
