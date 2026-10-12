
module Api
  module V1
    class PushNotificationsController < Api::V1::BaseController
      before_action :authenticate_user!

      # =====================================================
      # POST /api/v1/push_notifications/test
      # =====================================================

      def test
        unless Rails.env.development? ||
               Rails.env.staging? ||
               current_user.admin?
          return render json: {
            success: false,
            message: "Not authorised."
          }, status: :forbidden
        end

        unless current_user.push_tokens.exists?
          return render json: {
            success: false,
            message: "No registered devices found."
          }, status: :unprocessable_entity
        end

        SendPushNotificationJob.perform_later(
          current_user.id,
          "Book Pilot",
          "Your Rails push notification service is working!",
          {
            type: "test",
            source: "rails"
          }
        )

        render json: {
          success: true,
          message: "Test notification queued successfully."
        }, status: :accepted
      end
    end
  end
end
