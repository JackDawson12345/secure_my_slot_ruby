module Api
  module V1
    module Business
      class EmailTemplatesController < ApplicationController
        skip_before_action :verify_authenticity_token


        before_action :authenticate_user!
        before_action :set_business
        before_action :set_email_template,
                      only: [
                        :get_email_template,
                        :update_email_template,
                        :delete_email_template
                      ]

        # GET /api/v1/business/:id/email-templates
        def get_email_templates
          email_templates = @business.email_templates
                                     .where(custom: true)
                                     .order(updated_at: :desc)

          Rails.logger.info "======================================"
          Rails.logger.info "EMAIL TEMPLATE FEATURE CHECK"
          Rails.logger.info "Business ID: #{@business.id}"
          Rails.logger.info "Subscription: #{@business.subscription_level}"
          Rails.logger.info "Subscription raw: #{@business.subscription_level_before_type_cast}"
          Rails.logger.info "Pro?: #{@business.pro?}"
          Rails.logger.info "Pro Plus?: #{@business.pro_plus?}"
          Rails.logger.info "Custom templates?: #{@business.feature_enabled?(:custom_email_templates)}"
          Rails.logger.info "======================================"

          render json: {
            email_templates: email_templates.map do |template|
              serialize_email_template(template)
            end,
            feature_enabled: @business.feature_enabled?(:custom_email_templates)
          }, status: :ok
        end

        # GET /api/v1/business/:id/email-template/:email_template_id
        def get_email_template
          render json: {
            email_template: serialize_email_template(@email_template)
          }, status: :ok
        end

        # POST /api/v1/business/:id/email-templates
        def create_email_template
          email_template = @business.email_templates.new(
            email_template_params.except(
              :attachments,
              :remove_attachment_ids
            )
          )

          email_template.custom = true

          if email_template.save
            attach_new_files(email_template)

            render json: {
              message: "Email template created successfully.",
              email_template: serialize_email_template(
                email_template.reload
              )
            }, status: :created
          else
            render json: {
              message: "Unable to create email template.",
              errors: email_template.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/business/:id/email-template/:email_template_id
        def update_email_template
          if @email_template.update(
            email_template_params.except(
              :attachments,
              :remove_attachment_ids
            )
          )
            remove_selected_attachments
            attach_new_files(@email_template)

            render json: {
              message: "Email template updated successfully.",
              email_template: serialize_email_template(
                @email_template.reload
              )
            }, status: :ok
          else
            render json: {
              message: "Unable to update email template.",
              errors: @email_template.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/business/:id/email-template/:email_template_id
        def delete_email_template
          @email_template.destroy

          render json: {
            message: "Email template deleted successfully."
          }, status: :ok
        end

        private

        def set_business
          @business = current_user.business

          unless @business
            render json: {
              message: "Business not found."
            }, status: :not_found
            return
          end

          if @business.id.to_s != params[:id].to_s
            render json: {
              message: "You are not authorised to access this business."
            }, status: :forbidden
            return
          end
        end

        def set_email_template
          @email_template = @business.email_templates
                                     .where(custom: true)
                                     .find(params[:email_template_id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            message: "Email template not found."
          }, status: :not_found
        end

        def email_template_params
          params.require(:email_template).permit(
            :template_type,
            :subject,
            :body,
            attachments: [],
            remove_attachment_ids: []
          )
        end

        def remove_selected_attachments
          remove_attachment_ids.each do |attachment_id|
            attachment = @email_template.attachments.find_by(
              id: attachment_id
            )

            attachment&.purge
          end
        end

        def remove_attachment_ids
          Array(
            params.dig(
              :email_template,
              :remove_attachment_ids
            )
          ).reject(&:blank?)
        end

        def new_attachments
          Array(
            params.dig(
              :email_template,
              :attachments
            )
          ).reject(&:blank?)
        end

        def attach_new_files(email_template)
          new_attachments.each do |attachment|
            email_template.attachments.attach(attachment)
          end
        end

        def serialize_email_template(template)
          {
            id: template.id,
            template_type: template.template_type,
            subject: template.subject,
            body: template.body,
            custom: template.custom,
            attachments: serialize_attachments(template),
            created_at: template.created_at,
            updated_at: template.updated_at
          }
        end

        def serialize_attachments(template)
          return [] unless template.attachments.attached?

          template.attachments.map do |attachment|
            {
              id: attachment.id,
              filename: attachment.filename.to_s,
              content_type: attachment.content_type,
              byte_size: attachment.byte_size,
              url: rails_blob_url(
                attachment,
                disposition: "attachment"
              )
            }
          end
        end
      end
    end
  end
end