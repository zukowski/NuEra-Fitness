class Image < Asset
  has_attached_file :attachment,
                    :styles => {:mini => '48x48>', :small => '100x100>', :product => '240x240>', :large => '600x600>'},
                    :default_style => :product,
                    :path => 'assets/products/:id/:style/:basename.:extension',
                    :storage => 's3',
                    :s3_credentials => {
                      :access_key_id => ENV['S3_KEY'],
                      :secret_access_key => ENV['S3_SECRET']
                    },
                    :bucket => ENV['S3_BUCKET']
  
  def find_dimensions
    temporary = attachment.queued_for_write[:original]
    filename = temporary.path unless temporary.nil?
    filename = attachment.path if filename.blank?
    geometry = Paperclip::Geometry.from_file(filename)
    self.attachment_height = geometry.height
    self.attachment_width  = geometry.width
  end

  def validate
    unless attachment.errors.any?
      errors.add :attachment, "Paperclip returned errors from file '#{attachment_file_name}' - check ImageMagick installation or image source file."
    end
    false
  end
end
