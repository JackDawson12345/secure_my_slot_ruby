class SmsService
  def self.send_message(to:, body:)
    return if to.blank?

    client.messages.create(
      from: twilio_phone_number,
      to: format_phone_number(to),
      body: body
    )
  rescue Twilio::REST::RestError => e
    Rails.logger.error(
      "Twilio SMS failed: #{e.code} - #{e.message}"
    )

    false
  end

  def self.client
    @client ||= Twilio::REST::Client.new(
      account_sid,
      auth_token
    )
  end

  def self.account_sid
    ENV["TWILIO_ACCOUNT_SID"] ||
      Rails.application.credentials.dig(:twilio, :account_sid)
  end

  def self.auth_token
    ENV["TWILIO_AUTH_TOKEN"] ||
      Rails.application.credentials.dig(:twilio, :auth_token)
  end

  def self.twilio_phone_number
    ENV["TWILIO_PHONE_NUMBER"] ||
      Rails.application.credentials.dig(:twilio, :phone_number)
  end

  def self.format_phone_number(phone_number)
    cleaned_number = phone_number.gsub(/\s+/, "")

    if cleaned_number.start_with?("07")
      cleaned_number.sub(/^0/, "+44")
    else
      cleaned_number
    end
  end

  private_class_method :client,
                       :account_sid,
                       :auth_token,
                       :twilio_phone_number,
                       :format_phone_number
end