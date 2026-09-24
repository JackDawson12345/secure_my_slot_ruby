class Account::OrdersController < Account::BaseController
  def index
    @orders = current_user.orders
                          .includes(:business)
                          .order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find_by(id: params[:id])
  end
end
