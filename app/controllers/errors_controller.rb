class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def internal_server_error
    render status: :internal_server_error
  end

  def not_found
    render status: :not_found
  end
end