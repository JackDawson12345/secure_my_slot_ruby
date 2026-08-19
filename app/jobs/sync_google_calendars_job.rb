class SyncGoogleCalendarsJob < ApplicationJob
  queue_as :default

  def perform

    Rails.logger.info "Google calendar sync started"

    CalendarConnection.find_each do |connection|

      Rails.logger.info "Syncing connection #{connection.id}"

      GoogleCalendarService
        .new(connection)
        .sync_events

    rescue => e

      Rails.logger.error "Google sync failed: #{e.message}"

    end

    Rails.logger.info "Google calendar sync finished"

  end
end