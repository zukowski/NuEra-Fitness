Variant.class_eval do
  def options_text
    self.option_values.map {|ov| "#{ov.presentation}"}.to_sentence({:words_connector => ", ", :two_words_connector => ", "})
  end
end
