class WebpayController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:confirmation, :success, :failure]

  def show

  end

  def pay
    # Setup the payment
    @payment = TBK::Webpay::Payment.new({
      amount: 5000.0,
      order_id: SecureRandom.hex(6),
      success_url: webpay_success_url,
      confirmation_url: webpay_confirmation_url(host: self.class.public_ip, port: 80, protocol: 'http'),
      session_id: SecureRandom.hex(6),
      failure_url: webpay_failure_url # success_url is used by default
    })

    # Redirect the user to Webpay
    redirect_to @payment.redirect_url
  end

  # Confirmation callback executed from Webpay servers
  def confirmation
    # Read the confirmation data from the request
    @confirmation = TBK::Webpay::Confirmation.new(request.raw_post)

    # confirmation is invalid for some reason (wrong order_id or amount, double payment, etc...)
    if @confirmation.amount != 5000.0
      render text: @confirmation.reject
      return # reject and stop execution
    end

    if @confirmation.success?
      # EXITO!
      # perform everything you have to do here.
      self.last_confirmation = @confirmation
    end

    # Acknowledge payment
    render text: @confirmation.acknowledge
  end

  def success

  end

  def failure

  end

  # Hack to get the public IP of the current machine
  # You might want to provide a load balancer IP or something like that instead
  def self.public_ip
    @public_ip ||= `curl -s ifconfig.me`.strip
  end

  protected
    # Just a transient place to store the last confirmation received from Transbank
    mattr_accessor :last_confirmation
    delegate :last_confirmation, :last_confirmation=, to: "self.class"
    helper_method :last_confirmation
end
