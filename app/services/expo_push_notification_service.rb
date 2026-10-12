
require "net/http"
require "json"
require "uri"

class ExpoPushNotificationService
  EXPO_PUSH_URL = URI(
    "https://exp.host/--/api/v2/push/send"
  )

  MAX_BATCH_SIZE = 100

  class DeliveryError < StandardError; end

  def self.send_to_user(user:, title:, body:, data: {})
    return [] unless user

    tokens = user.push_tokens.pluck(:token)

    send_to_tokens(
      tokens: tokens,
      title: title,
      body: body,
      data: data
    )
  end

  def self.send_to_users(users:, title:, body:, data: {})
    user_ids = Array(users).map(&:id).compact.uniq

    return [] if user_ids.empty?

    tokens = PushToken.where(
      user_id: user_ids
    ).pluck(:token)

    send_to_tokens(
      tokens: tokens,
      title: title,
      body: body,
      data: data
    )
  end

  def self.send_to_tokens(tokens:, title:, body:, data: {})
    tokens = Array(tokens)
               .compact
               .uniq
               .select { |token| valid_token?(token) }

    return [] if tokens.empty?

    results = []

    tokens.each_slice(MAX_BATCH_SIZE) do |batch|
      messages = batch.map do |token|
        {
          to: token,
          title: title,
          body: body,
          data: data,
          sound: "default",
          priority: "high",
          channelId: "default"
        }
      end

      results.concat(
        deliver_batch(messages)
      )
    end

    results
  end

  private

  def self.valid_token?(token)
    token.is_a?(String) &&
      token.match?(
        /\A(?:ExponentPushToken|ExpoPushToken)\[[^\]]+\]\z/
      )
  end

  def self.deliver_batch(messages)
    request = Net::HTTP::Post.new(EXPO_PUSH_URL)

    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request["Accept-Encoding"] = "gzip, deflate"

    access_token = ENV["EXPO_ACCESS_TOKEN"]

    if access_token.present?
      request["Authorization"] = "Bearer #{access_token}"
    end

    request.body = JSON.generate(messages)

    response = Net::HTTP.start(
      EXPO_PUSH_URL.host,
      EXPO_PUSH_URL.port,
      use_ssl: true,
      open_timeout: 10,
      read_timeout: 20
    ) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise DeliveryError,
            "Expo returned HTTP #{response.code}: #{response.body}"
    end

    parsed = JSON.parse(response.body)

    tickets = parsed["data"]

    unless tickets.is_a?(Array) &&
           tickets.length == messages.length
      raise DeliveryError,
            "Unexpected Expo push response: #{response.body}"
    end

    tickets.each_with_index do |ticket, index|
      token = messages[index][:to]

      if ticket["status"] == "error"
        error_code = ticket.dig(
          "details",
          "error"
        )

        Rails.logger.warn(
          "Expo push rejected token: #{error_code}"
        )

        if error_code == "DeviceNotRegistered"
          PushToken.where(token: token).delete_all
        end
      end
    end

    tickets
  rescue JSON::ParserError => error
    raise DeliveryError,
          "Invalid Expo response: #{error.message}"
  end
end
