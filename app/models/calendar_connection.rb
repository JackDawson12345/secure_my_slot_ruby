class CalendarConnection < ApplicationRecord

  belongs_to :business

  has_many :calendar_blocked_times, dependent: :destroy

end
