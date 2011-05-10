Variant.class_eval do
  delegate :package, :to => :product
  delegate :supplier, :to => :product

  def options_text
    self.option_values.map {|ov| "#{ov.presentation}"}.to_sentence({:words_connector => ", ", :two_words_connector => ", "})
  end

  def is_a_package?
    !product.package.nil?
  end
end
