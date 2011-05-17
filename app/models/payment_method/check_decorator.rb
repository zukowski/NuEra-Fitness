PaymentMethod::Check.class_eval do
  def actions
    %w{capture void}
  end

  def can_capture?(payment)
    ['checkout','pending'].include?(payment.state)
  end

  def can_void?(payment)
    payment.state != 'void'
  end

  def capture(payment)
    payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
    payment.complete
    true
  end

  def void(payment)
    payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
    payment.void
    true
  end
end
