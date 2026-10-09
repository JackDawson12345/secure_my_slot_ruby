
module Api
  module V1
    module Agent
      class SettingsController < Api::V1::BaseController

        before_action :authenticate_api_key!
        before_action :authenticate_agent!
        before_action :set_business_agent!

        # ================================================
        # GET /api/v1/agent/:id/settings
        # ================================================

        def show
          render json: {
            success: true,
            message: "Agent settings loaded successfully.",

            user: user_json(@user),

            business: {
              id: @business.id,
              business_name: @business.business_name
            },

            permissions: {
              can_edit_profile: true,
              can_change_password: true
            }

          }, status: :ok
        end

        # ================================================
        # PATCH /api/v1/agent/:id/settings
        # ================================================

        def update
          if @user.update(user_params)
            render json: {
              success: true,
              message: "Settings updated successfully.",
              user: user_json(@user)
            }, status: :ok
          else
            render json: {
              success: false,
              message: "Please correct the errors below.",
              errors: @user.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # ================================================
        # PATCH /api/v1/agent/:id/settings/password
        # ================================================

        def update_password
          current_password = params[:current_password]
          new_password = params[:password]
          password_confirmation = params[:password_confirmation]

          # ----------------------------------------------
          # VALIDATE CURRENT PASSWORD
          # ----------------------------------------------

          if current_password.blank?
            return render json: {
              success: false,
              error: "Current password is required."
            }, status: :unprocessable_entity
          end

          unless @user.valid_password?(current_password)
            return render json: {
              success: false,
              error: "Current password is incorrect."
            }, status: :unprocessable_entity
          end

          # ----------------------------------------------
          # VALIDATE NEW PASSWORD
          # ----------------------------------------------

          if new_password.blank?
            return render json: {
              success: false,
              error: "New password is required."
            }, status: :unprocessable_entity
          end

          if new_password != password_confirmation
            return render json: {
              success: false,
              error: "Password confirmation does not match."
            }, status: :unprocessable_entity
          end

          # ----------------------------------------------
          # PASSWORD REQUIREMENTS
          # ----------------------------------------------

          password_errors = []

          if new_password.length < 8
            password_errors << "Password must be at least 8 characters long"
          end

          unless new_password.match?(/[A-Z]/)
            password_errors << "Password must contain at least one uppercase letter"
          end

          unless new_password.match?(/[0-9]/)
            password_errors << "Password must contain at least one number"
          end

          unless new_password.match?(/[^A-Za-z0-9]/)
            password_errors << "Password must contain at least one special character"
          end

          if password_errors.any?
            return render json: {
              success: false,
              message: "Password does not meet the requirements.",
              errors: password_errors
            }, status: :unprocessable_entity
          end

          # ----------------------------------------------
          # UPDATE PASSWORD
          # ----------------------------------------------

          if @user.update(
            password: new_password,
            password_confirmation: password_confirmation
          )
            render json: {
              success: true,
              message: "Password updated successfully."
            }, status: :ok
          else
            render json: {
              success: false,
              message: "Unable to update password.",
              errors: @user.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        # ================================================
        # API KEY AUTHENTICATION
        # ================================================

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]

          expected_api_key =
            ENV["SECURE_MY_SLOT_API_KEY"].presence ||
            Rails.application.credentials.secure_my_slot_api_key

          unless provided_api_key.present? &&
                 expected_api_key.present? &&
                 ActiveSupport::SecurityUtils.secure_compare(
                   provided_api_key,
                   expected_api_key
                 )

            render json: {
              success: false,
              error: "Invalid or missing API key"
            }, status: :unauthorized
          end
        end

        # ================================================
        # AGENT AUTHENTICATION
        # ================================================

        def authenticate_agent!
          return if performed?

          unless current_user && current_user.role.to_s == "agent"
            return render json: {
              success: false,
              error: "Agent authentication required"
            }, status: :unauthorized
          end

          unless params[:id].to_s == current_user.id.to_s
            return render json: {
              success: false,
              error: "You cannot access another agent's settings"
            }, status: :forbidden
          end
        end

        # ================================================
        # FIND AGENT'S BUSINESS
        # ================================================

        def set_business_agent!
          return if performed?

          memberships = ::BusinessAgent.where(
            user_id: current_user.id,
            status: "active"
          )

          if params[:business_id].present?
            memberships = memberships.where(
              business_id: params[:business_id]
            )
          elsif memberships.count > 1
            return render json: {
              success: false,
              error: "Please specify a business_id."
            }, status: :unprocessable_entity
          end

          @business_agent = memberships.first

          unless @business_agent
            return render json: {
              success: false,
              error: "Active business agent relationship not found."
            }, status: :not_found
          end

          @business = ::Business.find_by(
            id: @business_agent.business_id
          )

          unless @business
            return render json: {
              success: false,
              error: "Business not found."
            }, status: :not_found
          end

          @user = @business_agent.user
        end

        # ================================================
        # USER PARAMETERS
        # ================================================

        def user_params
          params.require(:user).permit(
            :first_name,
            :last_name,
            :email,
            :phone_number
          )
        end

        # ================================================
        # USER JSON
        # ================================================

        def user_json(user)
          {
            id: user.id,

            first_name: user.first_name,
            last_name: user.last_name,

            full_name: [
              user.first_name,
              user.last_name
            ].compact.join(" "),

            initials: [
              user.first_name.to_s.first,
              user.last_name.to_s.first
            ].join.upcase,

            email: user.email,
            phone_number: user.phone_number,

            role: user.role,

            created_at: user.created_at,

            agent_since: user.created_at.strftime("%B %Y")
          }
        end

      end
    end
  end
end
