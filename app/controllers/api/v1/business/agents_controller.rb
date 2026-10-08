module Api
  module V1
    module Business
      class AgentsController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        before_action :set_business

        before_action :set_business_agent,
                      only: %i[
                        get_agent
                        update_agent
                        delete_agent
                        resend_invitation
                      ]

        # =========================================================
        # GET AGENTS
        # =========================================================

        def get_agents
          business_agents = @business
                              .business_agents
                              .includes(:user)
                              .order(created_at: :desc)

          render json: {
            agents: business_agents.map do |business_agent|
              agent_json(business_agent)
            end,
            settings: settings_json(@business.agent_settings),
            feature_enabled: @business.feature_enabled?(:agents)
          }, status: :ok
        end

        # =========================================================
        # GET AGENT
        # =========================================================

        def get_agent
          render json: {
            agent: agent_json(@business_agent)
          }, status: :ok
        end

        # =========================================================
        # CREATE AGENT
        # =========================================================

        def create_agent
          unless @business.feature_enabled?(:agents)
            return render_upgrade_required
          end

          agent = User.find_by(
            email: agent_params[:email]
          )

          if agent
            add_existing_agent(agent)
          else
            create_new_agent
          end
        end

        # =========================================================
        # UPDATE AGENT
        # =========================================================

        def update_agent
          unless @business.feature_enabled?(:agents)
            return render_upgrade_required
          end

          agent = @business_agent.user

          User.transaction do
            agent.update!(agent_params.except(:email))

            @business_agent.update!(
              description: params[:description]
            )
          end

          render json: {
            message: "Agent updated successfully.",
            agent: agent_json(@business_agent.reload)
          }, status: :ok

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            error: "Unable to update agent.",
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # =========================================================
        # DELETE AGENT
        # =========================================================

        def delete_agent
          unless @business.feature_enabled?(:agents)
            return render_upgrade_required
          end

          @business_agent.destroy!

          render json: {
            message: "Agent removed successfully."
          }, status: :ok
        end

        # =========================================================
        # RESEND INVITATION
        # =========================================================

        def resend_invitation
          unless @business.feature_enabled?(:agents)
            return render_upgrade_required
          end

          agent = @business_agent.user

          send_agent_invitation(agent)

          @business_agent.update!(
            invited_at: Time.current
          )

          render json: {
            message: "Invitation resent successfully.",
            agent: agent_json(@business_agent.reload)
          }, status: :ok
        end

        # =========================================================
        # GET SETTINGS
        # =========================================================

        def get_settings
          render json: {
            settings: settings_json(
              @business.agent_settings
            )
          }, status: :ok
        end

        # =========================================================
        # UPDATE SETTINGS
        # =========================================================

        def update_settings
          unless @business.feature_enabled?(:agents)
            return render_upgrade_required
          end

          agent_setting = @business.agent_settings

          if agent_setting.update(agent_setting_params)
            render json: {
              message: "Agent settings updated successfully.",
              settings: settings_json(agent_setting)
            }, status: :ok
          else
            render json: {
              error: "Unable to update agent settings.",
              errors: agent_setting.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        # =========================================================
        # BUSINESS
        # =========================================================

        def set_business
          @business = current_user.business

          unless @business && @business.id.to_s == params[:id].to_s
            render json: {
              error: "Business not found."
            }, status: :not_found
          end
        end

        # =========================================================
        # BUSINESS AGENT
        # =========================================================

        def set_business_agent
          @business_agent = @business
                              .business_agents
                              .includes(:user)
                              .find(params[:agent_id])

        rescue ActiveRecord::RecordNotFound
          render json: {
            error: "Agent not found."
          }, status: :not_found
        end

        # =========================================================
        # USER PARAMS
        # These fields belong to User
        # =========================================================

        def agent_params
          params.require(:user).permit(
            :first_name,
            :last_name,
            :email,
            :phone_number
          )
        end

        # =========================================================
        # AGENT SETTINGS PARAMS
        # =========================================================

        def agent_setting_params
          params.require(:business_agent_setting).permit(
            :agent_selection,
            :booking_visibility,
            :allow_reassignment
          )
        end

        # =========================================================
        # CREATE NEW USER + BUSINESS AGENT
        # =========================================================

        def create_new_agent
          agent = User.new(agent_params)

          agent.role = :agent
          agent.invitation_creation = true
          agent.password = SecureRandom.hex(32)

          business_agent = nil

          User.transaction do
            agent.save!

            business_agent =
              @business.business_agents.create!(
                user: agent,
                status: :invited,
                invited_at: Time.current,
                description: params[:description]
              )
          end

          send_agent_invitation(agent)

          render json: {
            message: "Agent invitation sent successfully.",
            agent: agent_json(business_agent)
          }, status: :created

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            error: "Unable to create agent.",
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # =========================================================
        # ADD EXISTING USER AS AGENT
        # =========================================================

        def add_existing_agent(agent)
          if @business.business_agents.exists?(user: agent)
            return render json: {
              error: "Agent is already associated with this business.",
              errors: [
                "Email is already associated with this business"
              ]
            }, status: :unprocessable_entity
          end

          business_agent =
            @business.business_agents.create!(
              user: agent,
              status: :active,
              description: params[:description]
            )

          render json: {
            message: "Agent added successfully.",
            agent: agent_json(business_agent)
          }, status: :created

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            error: "Unable to add agent.",
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # =========================================================
        # SEND INVITATION
        # =========================================================

        def send_agent_invitation(agent)
          raw_token, encrypted_token =
            Devise.token_generator.generate(
              User,
              :reset_password_token
            )

          agent.update_columns(
            reset_password_token: encrypted_token,
            reset_password_sent_at: Time.current
          )

          AgentMailer
            .invitation(
              agent,
              @business,
              raw_token
            )
            .deliver_later
        end

        # =========================================================
        # AGENT JSON
        # =========================================================

        def agent_json(business_agent)
          user = business_agent.user

          {
            id: business_agent.id,
            user_id: user.id,

            first_name: user.first_name,
            last_name: user.last_name,
            full_name: user.full_name,

            email: user.email,
            phone_number: user.phone_number,

            # BusinessAgent field
            description: business_agent.description,

            status: business_agent.status,
            invited_at: business_agent.invited_at,

            created_at: business_agent.created_at,
            updated_at: business_agent.updated_at
          }
        end

        # =========================================================
        # SETTINGS JSON
        # =========================================================

        def settings_json(settings)
          {
            id: settings.id,
            agent_selection: settings.agent_selection,
            booking_visibility: settings.booking_visibility,
            allow_reassignment: settings.allow_reassignment
          }
        end

        # =========================================================
        # UPGRADE
        # =========================================================

        def render_upgrade_required
          render json: {
            error: "Upgrade required.",
            message: "Upgrade your plan to add and manage agents."
          }, status: :forbidden
        end

        # =========================================================
        # API KEY
        # =========================================================

        def authenticate_api_key!
          provided_api_key =
            request.headers["X-API-Key"]

          expected_api_key =
            ENV["SECURE_MY_SLOT_API_KEY"].presence ||
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
      end
    end
  end
end