class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  layout 'error'

  def internal_server_error
    render status: :internal_server_error
  end

  def not_found
    Rails.logger.info(
      "404 Not Found: #{request.path} from #{request.remote_ip}"
    )
    render status: :not_found
  end
end