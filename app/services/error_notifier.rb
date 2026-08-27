class ErrorNotifier

  def self.notify(exception, request, user = nil)

    AdminMailer.system_error(
      {
        class: exception.class.name,
        message: exception.message,
        backtrace: exception.backtrace&.first(30)
      },
      {
        url: request.original_url,
        method: request.request_method,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        request_id: request.request_id
      },
      user&.slice(:id, :email, :role)
    ).deliver_later

  end

end