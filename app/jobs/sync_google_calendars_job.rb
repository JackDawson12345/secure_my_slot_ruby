class SyncGoogleCalendarsJob < ApplicationJob
  queue_as :default

  def perform

    CalendarConnection.find_each do |connection|

      begin

        GoogleCalendarService
          .new(connection)
          .sync_events

      rescue => e

        Rails.logger.error(
          "Google Calendar sync failed for #{connection.id}: #{e.message}"
        )

      end

    end

  end
end