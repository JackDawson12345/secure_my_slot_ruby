module Api
  module V1
    class PushTokensController < Api::V1::BaseController
      before_action :authenticate_user!

      # =====================================================
      # POST /api/v1/push_tokens
      # =====================================================

      def create
        token = params[:token].to_s.strip
        platform = params[:platform].to_s.downcase

        unless token.present?
          return render json: {
            success: false,
            message: "Push token is required."
          }, status: :unprocessable_entity
        end

        unless %w[ios android].include?(platform)
          return render json: {
            success: false,
            message: "Invalid device platform."
          }, status: :unprocessable_entity
        end

        push_token = nil

        begin
          PushToken.transaction do
            push_token = PushToken.lock.find_or_initialize_by(
              token: token
            )

            push_token.user = current_user
            push_token.platform = platform
            push_token.save!
          end
        rescue ActiveRecord::RecordNotUnique
          # Handle concurrent registration of the same token.
          push_token = PushToken.find_by(token: token)

          return render json: {
            success: false,
            message: "Please retry device registration."
          }, status: :conflict
        end

        render json: {
          success: true,
          message: "Device registered successfully.",
          push_token: {
            id: push_token.id,
            platform: push_token.platform
          }
        }, status: :ok
      end

      # =====================================================
      # DELETE /api/v1/push_tokens
      # =====================================================

      def destroy
        token = params[:token].to_s.strip

        if token.blank?
          return render json: {
            success: false,
            message: "Push token is required."
          }, status: :unprocessable_entity
        end

        push_token = current_user.push_tokens.find_by(
          token: token
        )

        unless push_token
          return render json: {
            success: false,
            message: "Device registration not found."
          }, status: :not_found
        end

        push_token.destroy!

        render json: {
          success: true,
          message: "Device unregistered successfully."
        }, status: :ok
      end
    end
  end
end