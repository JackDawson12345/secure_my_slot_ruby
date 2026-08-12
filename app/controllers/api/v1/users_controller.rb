module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      skip_before_action :verify_authenticity_token

      def me
        render json: {
          user: {
            id: current_user.id,
            email: current_user.email,
            first_name: current_user.first_name,
            last_name: current_user.last_name,
            phone_number: current_user.phone_number,
            role: current_user.role,
            created_at: current_user.created_at
          }
        }, status: :ok
      end
    end
  end
end