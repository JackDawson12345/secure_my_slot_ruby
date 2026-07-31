module BusinessPortal
  class PaymentsController < BusinessPortal::BaseController
    before_action :authenticate_user!
    before_action :set_business

    def index
      refresh_stripe_status if @business.stripe_connected?
    rescue Stripe::StripeError => e
      flash.now[:alert] = "Stripe status could not be checked: #{e.message}"
    end

    def connect
      account = find_or_create_stripe_account
      account_link = create_account_link(account.id)

      redirect_to account_link.url,
                  allow_other_host: true,
                  status: :see_other
    rescue Stripe::StripeError => e
      redirect_to business_payments_path,
                  alert: "Stripe could not be connected: #{e.message}"
    end

    def stripe_return
      refresh_stripe_status

      if @business.stripe_ready?
        redirect_to business_payments_path,
                    notice: "Stripe has been connected successfully."
      else
        redirect_to business_payments_path,
                    alert: "Stripe needs some more information before payments can be accepted."
      end
    rescue Stripe::StripeError => e
      redirect_to business_payments_path,
                  alert: "Stripe status could not be checked: #{e.message}"
    end

    def stripe_refresh
      unless @business.stripe_connected?
        return redirect_to business_payments_path,
                           alert: "Connect Stripe first."
      end

      account_link = create_account_link(
        @business.stripe_account_id
      )

      redirect_to account_link.url,
                  allow_other_host: true,
                  status: :see_other
    rescue Stripe::StripeError => e
      redirect_to business_payments_path,
                  alert: "Stripe setup could not be reopened: #{e.message}"
    end

    private

    def set_business
      @business = current_user.business
    end

    def find_or_create_stripe_account
      if @business.stripe_connected?
        Stripe::Account.retrieve(
          @business.stripe_account_id
        )
      else
        create_stripe_account
      end
    end

    def create_stripe_account
      account = Stripe::Account.create(
        type: "express",
        country: "GB",
        email: current_user.email,
        capabilities: {
          card_payments: {
            requested: true
          },
          transfers: {
            requested: true
          }
        },
        metadata: {
          business_id: @business.id
        }
      )

      @business.update!(
        stripe_account_id: account.id
      )

      account
    end

    def create_account_link(account_id)
      Stripe::AccountLink.create(
        account: account_id,
        refresh_url: business_payments_refresh_url,
        return_url: business_payments_return_url,
        type: "account_onboarding"
      )
    end

    def refresh_stripe_status
      account = Stripe::Account.retrieve(
        @business.stripe_account_id
      )

      @business.update!(
        stripe_details_submitted: account.details_submitted,
        stripe_charges_enabled: account.charges_enabled,
        stripe_payouts_enabled: account.payouts_enabled
      )
    end
  end
end