module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      skip_before_action :verify_authenticity_token

      private

      def sign_up_params
        permitted = params.require(:user).permit(
          :first_name,
          :last_name,
          :email,
          :phone_number,
          :password,
          :password_confirmation,
          :terms_accepted
        ).merge(role: :customer)

        Rails.logger.info "SIGN UP PARAMS: #{permitted.inspect}"

        permitted
      end

      def respond_with(resource, _options = {})
        if resource.persisted?
          CustomerSetting.create!(user_id: resource.id)

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
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          phone_number: user.phone_number,
          role: user.role,
          created_at: user.created_at,
          terms_accepted: user.terms_accepted,
          terms_accepted_at: user.terms_accepted_at
        }
      end
    end
  end
end