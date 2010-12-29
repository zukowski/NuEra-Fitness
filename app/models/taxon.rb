class Taxon < ActiveRecord::Base
  acts_as_nested_set :dependant => :destroy

  belongs_to :taxonomy
  has_and_belongs_to_many :products
  before_create :set_permalink
  before_save :ensure_trailing_slash

  validates_presence_of :name
  has_attached_file :icon,
                    :styles => {:mini => '32x32>', :normal => '128x128>'},
                    :default_style => :mini,
                    :path => 'assets/taxons/:id/:style/:basename.:extension',
                    :storage => 's3',
                    :s3_credentials => {
                      :access_key_id => ENV['S3_KEY'],
                      :secret_access_key => ENV['S3_SECRET'],
                    },
                    :bucket => ENV['S3_BUCKET']
  
  include ::ProductFilters
  def applicable_filters
    fs = []
    fs << ProductFilters.taxons_below(self)
    fs += [
      ProductFilters.price_filter,
      ProductFilters.brand_filter,
      ProductFilters.selective_brand_filter(self) ]
  end

  def set_permalink
    if parent_id.nil?
      self.permalink = name.to_url + "/" if self.permalink.blank?
    else
      parent_taxon = Taxon.find(parent_id)
      self.permalink = parent_taxon.permalink + (self.permalink.blank? ? name.to_url : self.permalink.split("/").last) + "/"
    end
  end
end
