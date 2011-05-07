OrderMailer.class_eval do
  default :reply_to => Spree::Config[:reply_to_email_address]

  def quote_email(order, resend=false)
    @order = order
    subject = (resend ? "[RESEND] " : "")
    subject += "#{Spree::Config[:site_name]} Quote for Order ##{order.number}"
    mail(:to => order.email, :subject => subject)
  end
end
