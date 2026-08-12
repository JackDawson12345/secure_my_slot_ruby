module Api
  module V1
    module Business
      class DashboardController < Api::V1::BaseController
        before_action :require_business!

        def show
          render json: {
            message: "Business dashboard loaded.",
            user: {
              id: current_user.id,
              email: current_user.email,
              role: current_user.role
            }
          }, status: :ok
        end

      end
    end
  end
end