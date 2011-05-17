Payment.class_eval do
  def payment_source
    res = source.is_a?(Payment) ? source.source : source
    res || payment_method
  end
end
