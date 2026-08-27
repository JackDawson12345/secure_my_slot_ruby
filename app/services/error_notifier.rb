class ErrorNotifier

  def self.notify(exception, request, user = nil)

    AdminMailer.system_error(
      exception,
      request,
      user
    ).deliver_later

  end

end