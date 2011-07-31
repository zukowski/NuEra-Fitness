class AddTitleAndMetasToTaxons < ActiveRecord::Migration
  def self.up
    add_column :taxons, :page_title, :string
    add_column :taxons, :meta_keywords, :string
    add_column :taxons, :meta_description, :string
  end

  def self.down
    remove_column :taxons, :page_title
    remove_column :taxons, :meta_keywords
    remove_column :taxons, :meta_description
  end
end
