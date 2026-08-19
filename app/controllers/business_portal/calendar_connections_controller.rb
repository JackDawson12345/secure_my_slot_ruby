module BusinessPortal
  class CalendarConnectionsController < ApplicationController

    before_action :authenticate_user!


    def google
      redirect_to google_oauth_url, allow_other_host: true
    end


    def callback

      code = params[:code]

      raise "Missing Google code" unless code.present?

      business = current_user.business

      token = exchange_google_code(code)

      connection = business.create_calendar_connection!(
        provider: "google",
        access_token: token["access_token"],
        refresh_token: token["refresh_token"] || connection&.refresh_token,
        expires_at: Time.current + token["expires_in"].seconds
      )

      GoogleCalendarService.new(connection).sync_details

      redirect_to business_calendar_sync_path,
                  notice: "Google Calendar connected"

    end

    def sync
      connection = current_user.business.calendar_connection

      unless connection
        redirect_to business_calendar_sync_path,
                    alert: "Google Calendar is not connected."
        return
      end

      GoogleCalendarService.new(connection).sync_events

      redirect_to business_calendar_sync_path,
                  notice: "Google Calendar synced successfully."
    end

    private

    def google_oauth_url
      params = {
        client_id: ENV["GOOGLE_CLIENT_ID"] || Rails.application.credentials.dig(:google, :client_id),
        redirect_uri: business_google_calendar_callback_url,
        response_type: "code",
        scope: "https://www.googleapis.com/auth/calendar.readonly",
        access_type: "offline",
        prompt: "consent"
      }

      "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}"
    end

    def exchange_google_code(code)

      response = Faraday.post(
        "https://oauth2.googleapis.com/token",
        {
          client_id: ENV["GOOGLE_CLIENT_ID"] || Rails.application.credentials.dig(:google, :client_id),
          client_secret: ENV["GOOGLE_CLIENT_SECRET"] || Rails.application.credentials.dig(:google, :client_secret),
          code: code,
          grant_type: "authorization_code",
          redirect_uri: business_google_calendar_callback_url
        }
      )

      JSON.parse(response.body)

    end

  end
end