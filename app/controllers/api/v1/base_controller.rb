module Api
  module V1
    class BaseController < ApplicationController

      skip_before_action :verify_authenticity_token

      private

      def require_business!
        return if current_user.business?

        render json: {
          error: "Business account required."
        }, status: :forbidden
      end

      def require_customer!
        return if current_user.customer?

        render json: {
          error: "Customer account required."
        }, status: :forbidden
      end
    end
  end
end