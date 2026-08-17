module Api
  module V1
    module Business
      class PaymentsController < ApplicationController
        before_action :authenticate_user!
        before_action :set_business

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

        def connect
          account = find_or_create_stripe_account

          account_link = create_account_link(
            account.id
          )

          render json: {
            onboarding_url: account_link.url,
            stripe_account_id: account.id
          }, status: :ok
        rescue Stripe::StripeError => e
          render_stripe_error(
            "Stripe could not be connected.",
            e
          )
        end

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

        def refresh
          unless @business.stripe_connected?
            return render json: {
              error: "Connect Stripe first."
            }, status: :unprocessable_entity
          end

          account_link = create_account_link(
            @business.stripe_account_id
          )

          render json: {
            onboarding_url: account_link.url
          }, status: :ok
        rescue Stripe::StripeError => e
          render_stripe_error(
            "Stripe setup could not be reopened.",
            e
          )
        end

        private

        def set_business
          @business = current_user.business

          unless @business &&
                 @business.id == params[:id].to_i
            render json: {
              error: "Business not found."
            }, status: :not_found
          end
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

        def payment_response
          {
            stripe_account_id: @business.stripe_account_id,
            stripe_connected: @business.stripe_connected?,
            stripe_details_submitted: @business.stripe_details_submitted?,
            stripe_charges_enabled: @business.stripe_charges_enabled?,
            stripe_payouts_enabled: @business.stripe_payouts_enabled?,
            stripe_ready: @business.stripe_ready?
          }
        end

        def render_stripe_error(message, exception)
          render json: {
            error: message,
            message: exception.message
          }, status: :unprocessable_entity
        end
      end
    end
  end
end