module Api
  module V1
    class PasswordsController < BaseController
      skip_before_action :verify_authenticity_token

      # POST /api/v1/forgot_password
      def create
        email = params[:email].to_s.strip.downcase

        user = User.find_by(email: email)

        if user
          user.send_reset_password_instructions
        end

        # Always return the same response.
        # This prevents people checking which email addresses
        # have accounts on your platform.
        render json: {
          message: "If an account exists for that email address, password reset instructions have been sent."
        }, status: :ok
      end

      # PATCH /api/v1/reset_password
      def update
        user = User.reset_password_by_token(
          reset_password_token: params[:reset_password_token],
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )

        if user.errors.empty?
          render json: {
            message: "Password updated successfully."
          }, status: :ok
        else
          render json: {
            message: "Password could not be updated.",
            errors: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end
end