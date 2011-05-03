Creditcard.class_eval do
  def void(payment)
    response = payment_gateway.void(payment.response_code, self, minimal_gateway_options(payment))
    record_log payment, response
    if response.success?
      payment.response_code = response.authorization
      payment.void
    else
      gateway_error(response)
    end
  rescue ActiveMerchant::ConnectionError => e
    gateway_error I18n.t(:unable_to_connect_to_gateway)
  end
end
