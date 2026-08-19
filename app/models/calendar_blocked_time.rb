class CalendarBlockedTime < ApplicationRecord
  belongs_to :business
  belongs_to :calendar_connection
end
