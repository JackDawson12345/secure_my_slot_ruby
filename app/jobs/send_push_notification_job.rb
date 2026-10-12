
class SendPushNotificationJob < ApplicationJob
  queue_as :default

  retry_on ExpoPushNotificationService::DeliveryError,
           Net::OpenTimeout,
           Net::ReadTimeout,
           SocketError,
           wait: :polynomially_longer,
           attempts: 5

  def perform(user_id, title, body, data = {})
    user = User.find_by(id: user_id)

    unless user
      Rails.logger.warn(
        "PUSH: User #{user_id} not found"
      )
      return
    end

    if user.push_tokens.none?
      Rails.logger.info(
        "PUSH: No registered devices for user #{user_id}"
      )
      return
    end

    tickets = ExpoPushNotificationService.send_to_user(
      user: user,
      title: title,
      body: body,
      data: data
    )

    Rails.logger.info(
      "PUSH: Processed #{tickets.length} notification tickets for user #{user_id}"
    )
  end
end
