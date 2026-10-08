module Api
  module V1
    module Business
      class AgreementsController < ApplicationController
        skip_before_action :verify_authenticity_token

        before_action :set_business

        before_action :set_agreement,
                      only: %i[
                        get_agreement
                        update_agreement
                        delete_agreement
                      ]

        before_action :check_agreements_access,
                      only: %i[
                        create_agreement
                        update_agreement
                        delete_agreement
                      ]

        # GET /api/v1/business/:id/agreements
        def get_agreements
          agreements = @business.agreements.order(
            created_at: :desc
          )

          render json: {
            feature_enabled: @business.feature_enabled?(:agreements),
            agreements: agreements.map do |agreement|
              agreement_json(agreement)
            end
          }, status: :ok
        end

        # GET /api/v1/business/:id/agreement/:agreement_id
        def get_agreement
          render json: {
            feature_enabled: @business.feature_enabled?(:agreements),
            agreement: agreement_json(@agreement)
          }, status: :ok
        end

        # POST /api/v1/business/:id/agreements
        def create_agreement
          agreement = @business.agreements.build(
            agreement_params
          )

          if agreement.save
            render json: {
              message: "Agreement created successfully.",
              agreement: agreement_json(agreement)
            }, status: :created
          else
            render json: {
              message: "Unable to create agreement.",
              errors: agreement.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/business/:id/agreement/:agreement_id
        def update_agreement
          if @agreement.update(agreement_params)
            render json: {
              message: "Agreement updated successfully.",
              agreement: agreement_json(@agreement)
            }, status: :ok
          else
            render json: {
              message: "Unable to update agreement.",
              errors: @agreement.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/business/:id/agreement/:agreement_id
        def delete_agreement
          @agreement.destroy

          render json: {
            message: "Agreement deleted successfully."
          }, status: :ok
        end

        private

        def set_business
          @business = current_user.business

          unless @business.present? &&
                 @business.id.to_s == params[:id].to_s
            render json: {
              message: "Business not found."
            }, status: :not_found
          end
        end

        def set_agreement
          @agreement = @business.agreements.find(
            params[:agreement_id]
          )
        rescue ActiveRecord::RecordNotFound
          render json: {
            message: "Agreement not found."
          }, status: :not_found
        end

        def agreement_params
          params.require(:agreement).permit(
            :name,
            :content
          )
        end

        def check_agreements_access
          return if @business.feature_enabled?(:agreements)

          render json: {
            message: "Upgrade to Pro Plus to use agreements.",
            feature: "agreements",
            upgrade_required: true
          }, status: :forbidden
        end

        def agreement_json(agreement)
          {
            id: agreement.id,
            name: agreement.name,
            content: agreement.content,
            created_at: agreement.created_at,
            updated_at: agreement.updated_at
          }
        end
      end
    end
  end
end