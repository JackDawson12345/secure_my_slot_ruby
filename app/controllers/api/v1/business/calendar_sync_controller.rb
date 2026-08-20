module Api
  module V1
    module Business
      class CalendarSyncController < ApplicationController

        skip_before_action :verify_authenticity_token

        def show
          connection = current_user.business.calendar_connection


          if connection
            render json: {
              connected: true,
              provider: connection.provider,
              email: connection.email,
              calendar_id: connection.calendar_id,
              last_synced_at: connection.last_synced_at
            }
          else
            render json: {
              connected: false
            }
          end
        end




        def connect
          state = generate_oauth_state(current_user)


          render json: {
            url: google_oauth_url(state)
          }
        end




        def callback
          code = params[:code]
          state = params[:state]


          raise "Missing Google code" unless code.present?
          raise "Missing OAuth state" unless state.present?


          user = verify_oauth_state(state)


          token = exchange_google_code(code)


          business = user.business


          existing_connection = business.calendar_connection


          connection = if existing_connection
                         existing_connection.update!(
                           provider: "google",
                           access_token: token["access_token"],
                           refresh_token: token["refresh_token"].presence || existing_connection.refresh_token,
                           expires_at: Time.current + token["expires_in"].seconds
                         )


                         existing_connection
                       else
                         business.create_calendar_connection!(
                           provider: "google",
                           access_token: token["access_token"],
                           refresh_token: token["refresh_token"],
                           expires_at: Time.current + token["expires_in"].seconds
                         )
                       end


          GoogleCalendarService.new(connection).sync_details
          GoogleCalendarService.new(connection).sync_events


          redirect_to "securemyslot://calendar-connected?success=true"


        rescue => e
          Rails.logger.error(
            "Google Calendar connection failed: #{e.class}: #{e.message}"
          )


          redirect_to "securemyslot://calendar-connected?success=false"
        end




        def sync
          connection = current_user.business.calendar_connection


          unless connection
            render json: {
              connected: false,
              error: "Google Calendar is not connected."
            }, status: :unprocessable_entity


            return
          end


          GoogleCalendarService.new(connection).sync_events


          render json: {
            connected: true,
            synced: true,
            last_synced_at: connection.reload.last_synced_at
          }
        end




        def disconnect
          connection = current_user.business.calendar_connection


          if connection
            CalendarBlockedTime
              .where(calendar_connection: connection)
              .destroy_all


            connection.destroy
          end


          render json: {
            connected: false
          }
        end




        private




        def google_oauth_url(state)
          params = {
            client_id: google_client_id,
            redirect_uri: api_v1_business_calendar_sync_callback_url,
            response_type: "code",
            scope: "https://www.googleapis.com/auth/calendar.readonly",
            access_type: "offline",
            prompt: "consent",
            state: state
          }


          "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}"
        end




        def exchange_google_code(code)
          response = Faraday.post(
            "https://oauth2.googleapis.com/token",
            {
              client_id: google_client_id,
              client_secret: google_client_secret,
              code: code,
              grant_type: "authorization_code",
              redirect_uri: api_v1_business_calendar_sync_callback_url
            }
          )


          body = JSON.parse(response.body)


          unless response.success?
            raise "Google token exchange failed: #{body}"
          end


          body
        end




        def generate_oauth_state(user)
          verifier = Rails.application.message_verifier(
            "google-calendar-oauth"
          )


          verifier.generate(
            {
              user_id: user.id
            },
            expires_in: 10.minutes
          )
        end




        def verify_oauth_state(state)
          verifier = Rails.application.message_verifier(
            "google-calendar-oauth"
          )


          data = verifier.verify(state)


          User.find(data.fetch(:user_id))
        rescue ActiveSupport::MessageVerifier::InvalidSignature,
          ActiveRecord::RecordNotFound,
          KeyError


          raise "Invalid Google OAuth state"
        end




        def google_client_id
          ENV["GOOGLE_CLIENT_ID"] ||
            Rails.application.credentials.dig(:google, :client_id)
        end




        def google_client_secret
          ENV["GOOGLE_CLIENT_SECRET"] ||
            Rails.application.credentials.dig(:google, :client_secret)
        end


      end
    end
  end
end






