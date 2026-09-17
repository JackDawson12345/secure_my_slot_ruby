class BirthdayReminderMessage < ApplicationRecord
  belongs_to :business

  validates :text, presence: true
end
