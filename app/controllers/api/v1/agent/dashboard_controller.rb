module Api
  module V1
    module Agent
      class DashboardController < Api::V1::BaseController
        before_action :require_agent!

        def show
          render json: {
            message: "Agent dashboard loaded.",
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