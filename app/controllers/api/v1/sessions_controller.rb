module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json

      skip_before_action :verify_authenticity_token

      def create
        email = params.dig(:user, :email).to_s.strip.downcase
        password = params.dig(:user, :password).to_s

        user = User.find_for_database_authentication(email: email)

        unless user&.valid_password?(password)
          render json: {
            error: "Invalid email or password."
          }, status: :unauthorized

          return
        end

        sign_out(current_user) if current_user.present?
        sign_in(:user, user, store: false)

        render json: {
          message: "Signed in successfully",
          user: {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at
          }
        }, status: :ok
      end

      def destroy
        if current_user
          sign_out(:user)

          render json: {
            message: "Signed out successfully"
          }, status: :ok
        else
          render json: {
            error: "No active session found."
          }, status: :unauthorized
        end
      end
    end
  end
end