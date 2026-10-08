
module BusinessPortal
  class PaymentsController < BusinessPortal::BaseController
    before_action :authenticate_user!
    before_action :set_business

    # =========================================================
    # INDEX
    # =========================================================

    def index
    end

    # =========================================================
    # STRIPE SETTINGS
    # =========================================================

    def stripe
      refresh_stripe_status if @business.stripe_connected?

    rescue Stripe::StripeError => e
      Rails.logger.error(
        "Stripe status error for business #{@business.id}: " \
          "#{e.class} - #{e.message}"
      )

      flash.now[:alert] =
        "Stripe status could not be checked: #{e.message}"
    end

    # =========================================================
    # CONNECT STRIPE
    # =========================================================

    def connect
      account = find_or_create_stripe_account

      Rails.logger.info(
        "Stripe account found/created for business " \
          "#{@business.id}: #{account.id}"
      )

      account_link = create_account_link(account.id)

      redirect_to(
        account_link.url,
        allow_other_host: true,
        status: :see_other
      )

    rescue Stripe::StripeError => e
      Rails.logger.error(
        "Stripe Connect error for business #{@business.id}: " \
          "#{e.class} - #{e.message}"
      )

      redirect_to(
        business_payments_path,
        alert: "Stripe could not be connected: #{e.message}",
        status: :see_other
      )
    end

    # =========================================================
    # DISCONNECT STRIPE
    #
    # Disconnect locally.
    # Do not delete the actual Stripe account.
    # =========================================================

    def disconnect
      unless @business.stripe_connected?
        return redirect_to(
          business_payments_path,
          alert: "Stripe is not connected.",
          status: :see_other
        )
      end

      old_stripe_account_id = @business.stripe_account_id

      @business.update!(
        stripe_account_id: nil,
        stripe_details_submitted: false,
        stripe_charges_enabled: false,
        stripe_payouts_enabled: false
      )

      Rails.logger.info(
        "Stripe disconnected locally for business " \
          "#{@business.id}. " \
          "Previous account: #{old_stripe_account_id}"
      )

      redirect_to(
        business_payments_path,
        notice: "Stripe has been disconnected successfully.",
        status: :see_other
      )

    rescue ActiveRecord::RecordInvalid,
      ActiveRecord::RecordNotSaved => e

      Rails.logger.error(
        "Stripe disconnect failed for business " \
          "#{@business.id}: #{e.class} - #{e.message}"
      )

      redirect_to(
        business_payments_path,
        alert: "Stripe could not be disconnected.",
        status: :see_other
      )
    end

    # =========================================================
    # STRIPE ONBOARDING RETURN
    # =========================================================

    def stripe_return
      refresh_stripe_status

      if @business.stripe_ready?
        redirect_to(
          business_payments_path,
          notice: "Stripe has been connected successfully.",
          status: :see_other
        )
      else
        redirect_to(
          business_payments_path,
          alert: "Stripe needs some more information before payments can be accepted.",
          status: :see_other
        )
      end

    rescue Stripe::StripeError => e
      redirect_to(
        business_payments_path,
        alert: "Stripe status could not be checked: #{e.message}",
        status: :see_other
      )
    end

    # =========================================================
    # REFRESH STRIPE ONBOARDING
    # =========================================================

    def stripe_refresh
      unless @business.stripe_connected?
        return redirect_to(
          business_payments_path,
          alert: "Connect Stripe first.",
          status: :see_other
        )
      end

      account_link = create_account_link(
        @business.stripe_account_id
      )

      redirect_to(
        account_link.url,
        allow_other_host: true,
        status: :see_other
      )

    rescue Stripe::StripeError => e
      redirect_to(
        business_payments_path,
        alert: "Stripe setup could not be reopened: #{e.message}",
        status: :see_other
      )
    end

    private

    # =========================================================
    # SET BUSINESS
    # =========================================================

    def set_business
      @business = current_user.business
    end

    # =========================================================
    # FIND OR CREATE STRIPE ACCOUNT
    # =========================================================

    def find_or_create_stripe_account
      if @business.stripe_connected?
        Stripe::Account.retrieve(
          @business.stripe_account_id
        )
      else
        create_stripe_account
      end
    end

    # =========================================================
    # CREATE STRIPE CONNECT ACCOUNT
    # =========================================================

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
        stripe_account_id: account.id,
        stripe_details_submitted: false,
        stripe_charges_enabled: false,
        stripe_payouts_enabled: false
      )

      Rails.logger.info(
        "New Stripe Connect account #{account.id} " \
          "created for business #{@business.id}"
      )

      account
    end

    # =========================================================
    # CREATE ACCOUNT ONBOARDING LINK
    # =========================================================

    def create_account_link(account_id)
      Stripe::AccountLink.create(
        account: account_id,
        refresh_url: business_payments_refresh_url,
        return_url: business_payments_return_url,
        type: "account_onboarding"
      )
    end

    # =========================================================
    # REFRESH STRIPE STATUS
    # =========================================================

    def refresh_stripe_status
      return unless @business.stripe_connected?

      account = Stripe::Account.retrieve(
        @business.stripe_account_id
      )

      @business.update!(
        stripe_details_submitted: account.details_submitted,
        stripe_charges_enabled: account.charges_enabled,
        stripe_payouts_enabled: account.payouts_enabled
      )

      Rails.logger.info(
        "Stripe status refreshed for business " \
          "#{@business.id}. " \
          "Charges: #{account.charges_enabled}, " \
          "Payouts: #{account.payouts_enabled}"
      )
    end
  end
end
