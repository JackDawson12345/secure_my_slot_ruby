module Api
  module V1
    module Business
      class PaymentsController < ApplicationController
        skip_before_action :verify_authenticity_token

        before_action :authenticate_user!,
                      except: [
                        :stripe_return,
                        :stripe_refresh
                      ]

        before_action :set_business,
                      except: [
                        :stripe_return,
                        :stripe_refresh
                      ]

        before_action :set_callback_business,
                      only: [
                        :stripe_return,
                        :stripe_refresh
                      ]


        # ============================================================
        # GET /api/v1/business/:id/payments
        #
        # Returns the current Stripe status for the business.
        #
        # We retrieve the latest status from Stripe first when
        # an account has already been connected.
        # ============================================================

        def index
          refresh_stripe_status if @business.stripe_connected?

          render json: payment_response,
                 status: :ok

        rescue Stripe::StripeError => e
          render_stripe_error(
            "Stripe status could not be checked.",
            e
          )
        end


        # ============================================================
        # POST /api/v1/business/:id/payments/connect
        #
        # Creates the Stripe Express account when required and
        # returns a Stripe onboarding URL for the Expo app.
        # ============================================================

        def connect
          account =
            find_or_create_stripe_account

          account_link =
            create_account_link(
              account.id
            )

          render json: {
            onboarding_url:
              account_link.url,

            stripe_account_id:
              account.id
          }, status: :ok

        rescue Stripe::StripeError => e
          render_stripe_error(
            "Stripe could not be connected.",
            e
          )
        end


        # ============================================================
        # GET /api/v1/business/:id/payments/status
        #
        # Explicit endpoint for refreshing Stripe status.
        #
        # The normal GET /payments endpoint already does this,
        # but this endpoint can still be useful separately.
        # ============================================================

        def status
          refresh_stripe_status if @business.stripe_connected?

          render json: payment_response,
                 status: :ok

        rescue Stripe::StripeError => e
          render_stripe_error(
            "Stripe status could not be checked.",
            e
          )
        end


        # ============================================================
        # POST /api/v1/business/:id/payments/refresh
        #
        # Called by Expo when a business already has a Stripe
        # account but onboarding is incomplete.
        #
        # Returns a fresh Stripe onboarding URL.
        # ============================================================

        def refresh
          unless @business.stripe_connected?
            return render json: {
              error:
                "Connect Stripe first."
            }, status: :unprocessable_entity
          end

          account_link =
            create_account_link(
              @business.stripe_account_id
            )

          render json: {
            onboarding_url:
              account_link.url
          }, status: :ok

        rescue Stripe::StripeError => e
          render_stripe_error(
            "Stripe setup could not be reopened.",
            e
          )
        end


        # ============================================================
        # GET /api/v1/business/:id/payments/stripe-return
        #
        # Stripe sends the browser here after onboarding.
        #
        # This endpoint must NOT require JWT authentication because
        # Stripe's browser redirect will not contain the Expo app's
        # Authorization header.
        #
        # Once Stripe has been checked, Rails redirects back into
        # the Expo app.
        # ============================================================

        def stripe_return
          refresh_stripe_status

          if @business.stripe_ready?
            redirect_to(
              mobile_return_url(
                status: "success"
              ),
              allow_other_host: true,
              status: :see_other
            )
          else
            redirect_to(
              mobile_return_url(
                status: "incomplete"
              ),
              allow_other_host: true,
              status: :see_other
            )
          end

        rescue Stripe::StripeError => e
          Rails.logger.error(
            "Stripe return error for business #{@business&.id}: #{e.message}"
          )

          redirect_to(
            mobile_return_url(
              status: "error"
            ),
            allow_other_host: true,
            status: :see_other
          )
        end


        # ============================================================
        # GET /api/v1/business/:id/payments/stripe-refresh
        #
        # This is Stripe's AccountLink refresh_url.
        #
        # Stripe uses this when an onboarding link expires or needs
        # to be regenerated.
        #
        # We create a fresh AccountLink and send the browser back
        # into Stripe onboarding.
        # ============================================================

        def stripe_refresh
          unless @business.stripe_connected?
            return redirect_to(
              mobile_return_url(
                status: "error"
              ),
              allow_other_host: true,
              status: :see_other
            )
          end

          account_link =
            create_account_link(
              @business.stripe_account_id
            )

          redirect_to(
            account_link.url,
            allow_other_host: true,
            status: :see_other
          )

        rescue Stripe::StripeError => e
          Rails.logger.error(
            "Stripe refresh error for business #{@business&.id}: #{e.message}"
          )

          redirect_to(
            mobile_return_url(
              status: "error"
            ),
            allow_other_host: true,
            status: :see_other
          )
        end


        private

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]
          expected_api_key = ENV["SECURE_MY_SLOT_API_KEY"].presence ||
                             Rails.application.credentials.secure_my_slot_api_key

          unless provided_api_key.present? &&
                 expected_api_key.present? &&
                 ActiveSupport::SecurityUtils.secure_compare(
                   provided_api_key,
                   expected_api_key
                 )
            render json: {
              error: "Invalid or missing API key"
            }, status: :unauthorized
          end
        end


        # ============================================================
        # Authenticated API business
        # ============================================================

        def set_business
          @business =
            current_user.business

          unless @business &&
                 @business.id ==
                 params[:id].to_i

            return render json: {
              error:
                "Business not found."
            }, status: :not_found
          end
        end


        # ============================================================
        # Stripe callback business
        #
        # There is no current_user here because these requests come
        # from the Stripe browser redirect rather than an authenticated
        # Expo API request.
        # ============================================================

        def set_callback_business
          @business =
            ::Business.find_by(
              id: params[:id]
            )

          return if @business

          redirect_to(
            mobile_return_url(
              status: "error"
            ),
            allow_other_host: true,
            status: :see_other
          )
        end


        # ============================================================
        # Find existing Stripe account or create one.
        # ============================================================

        def find_or_create_stripe_account
          if @business.stripe_connected?
            Stripe::Account.retrieve(
              @business.stripe_account_id
            )
          else
            create_stripe_account
          end
        end


        # ============================================================
        # Create Stripe Express Connect account.
        # ============================================================

        def create_stripe_account
          account =
            Stripe::Account.create(
              type: "express",

              country: "GB",

              email:
                current_user.email,

              capabilities: {
                card_payments: {
                  requested: true
                },

                transfers: {
                  requested: true
                }
              },

              metadata: {
                business_id:
                  @business.id
              }
            )

          @business.update!(
            stripe_account_id:
              account.id
          )

          account
        end


        # ============================================================
        # Generate Stripe onboarding link.
        #
        # These are API callback URLs rather than your existing
        # BusinessPortal callback URLs.
        # ============================================================

        def create_account_link(account_id)
          Stripe::AccountLink.create(
            account: account_id,

            refresh_url:
              api_v1_business_payments_stripe_refresh_url(
                id: @business.id
              ),

            return_url:
              api_v1_business_payments_stripe_return_url(
                id: @business.id
              ),

            type:
              "account_onboarding"
          )
        end


        # ============================================================
        # Retrieve latest account state from Stripe.
        # ============================================================

        def refresh_stripe_status
          return unless @business.stripe_connected?

          account =
            Stripe::Account.retrieve(
              @business.stripe_account_id
            )

          @business.update!(
            stripe_details_submitted:
              account.details_submitted,

            stripe_charges_enabled:
              account.charges_enabled,

            stripe_payouts_enabled:
              account.payouts_enabled
          )
        end


        # ============================================================
        # Standard JSON response used by Expo.
        # ============================================================

        def payment_response
          {
            stripe_account_id:
              @business.stripe_account_id,

            stripe_connected:
              @business.stripe_connected?,

            stripe_details_submitted:
              @business.stripe_details_submitted?,

            stripe_charges_enabled:
              @business.stripe_charges_enabled?,

            stripe_payouts_enabled:
              @business.stripe_payouts_enabled?,

            stripe_ready:
              @business.stripe_ready?
          }
        end


        # ============================================================
        # Expo deep link.
        #
        # WebBrowser.openAuthSessionAsync is listening for:
        #
        # securemyslot://stripe-connect-return
        # ============================================================

        def mobile_return_url(status:)
          [
            "securemyslot://stripe-connect-return",
            "?status=#{status}",
            "&business_id=#{@business&.id}"
          ].join
        end


        # ============================================================
        # Standard Stripe API error response.
        # ============================================================

        def render_stripe_error(message, exception)
          Rails.logger.error(
            "#{message} #{exception.message}"
          )

          render json: {
            error: message,
            message:
              exception.message
          }, status: :unprocessable_entity
        end
      end
    end
  end
end