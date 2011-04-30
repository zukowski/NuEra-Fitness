class PackagesVariants < ActiveRecord::Migration
  def self.up
    create_table :packages_variants, :id => false do |t|
      t.integer :package_id
      t.integer :variant_id
    end
  end

  def self.down
    drop_table :packages_variants
  end
end
