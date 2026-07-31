module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      skip_before_action :verify_authenticity_token

      private

      def sign_up_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation
        ).merge(role: :customer)
      end

      def respond_with(resource, _options = {})
        if resource.persisted?
          render json: {
            message: "Account created successfully",
            user: user_json(resource)
          }, status: :created
        else
          render json: {
            message: "Account could not be created",
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          role: user.role,
          created_at: user.created_at
        }
      end
    end
  end
end