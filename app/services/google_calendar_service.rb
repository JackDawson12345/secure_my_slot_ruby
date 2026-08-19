class GoogleCalendarService

  def initialize(calendar_connection)
    @calendar_connection = calendar_connection
  end


  def sync_details

    calendars = calendar_list

    primary = calendars["items"].find do |calendar|
      calendar["primary"]
    end

    return unless primary

    @calendar_connection.update!(
      email: primary["id"],
      calendar_id: primary["id"]
    )

  end


  def sync_events

    response = Faraday.get(
      "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_connection.calendar_id}/events",
      {
        maxResults: 250,
        singleEvents: true,
        orderBy: "startTime",
        timeMin: Time.current.iso8601
      },
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      }
    )


    events = JSON.parse(response.body)


    events.fetch("items", []).each do |event|

      next if event["status"] == "cancelled"


      start_time = event.dig("start", "dateTime")
      end_time   = event.dig("end", "dateTime")


      # Ignore all-day events for now
      next unless start_time && end_time


      start_time = Time.parse(start_time)
      end_time   = Time.parse(end_time)


      sync_event(
        event,
        start_time,
        end_time
      )

    end


    @calendar_connection.update!(
      last_synced_at: Time.current
    )

  end


  private


  def sync_event(event, start_time, end_time)

    business = @calendar_connection.business


    existing = CalendarBlockedTime.find_or_initialize_by(
      business: business,
      source: "google",
      external_id: event["id"]
    )

    existing.calendar_connection = @calendar_connection


    overlapping = CalendarBlockedTime
                    .where(
                      business: business,
                      source: "google"
                    )
                    .where(
                      "starts_at < ? AND ends_at > ?",
                      end_time,
                      start_time
                    )
                    .where.not(
      external_id: event["id"]
    )


    if overlapping.exists?

      overlapping_block = overlapping.order(:starts_at).first


      overlapping_block.update!(
        calendar_connection: @calendar_connection,

        starts_at: [
          overlapping_block.starts_at,
          start_time
        ].min,

        ends_at: [
          overlapping_block.ends_at,
          end_time
        ].max,

        title: "Google Calendar unavailable",

        notes: "Merged Google Calendar events"
      )

    else

      existing.update!(
        title: clean_title(event["summary"]),

        starts_at: start_time,

        ends_at: end_time,

        all_day: false,

        notes: "Imported from Google Calendar"

      )

    end

  end


  def calendar_list

    response = Faraday.get(
      "https://www.googleapis.com/calendar/v3/users/me/calendarList",
      nil,
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      }
    )

    JSON.parse(response.body)

  end


  def clean_title(title)

    return "Google Calendar Event" if title.blank?

    ActionController::Base.helpers.strip_tags(title)

  end


  def access_token

    if @calendar_connection.expires_at <= Time.current
      refresh_access_token
    end

    @calendar_connection.access_token

  end

  def refresh_access_token

    response = Faraday.post(
      "https://oauth2.googleapis.com/token",
      {
        client_id: Rails.application.credentials.dig(:google, :client_id),
        client_secret: Rails.application.credentials.dig(:google, :client_secret),
        refresh_token: @calendar_connection.refresh_token,
        grant_type: "refresh_token"
      }
    )


    token = JSON.parse(response.body)


    @calendar_connection.update!(
      access_token: token["access_token"],
      expires_at: Time.current + token["expires_in"].seconds
    )

  end

end