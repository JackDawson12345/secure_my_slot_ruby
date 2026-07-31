class BusinessOpeningHourBreak < ApplicationRecord
  belongs_to :business_opening_hour,
             inverse_of: :breaks

  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if starts_at.blank? || ends_at.blank?

    if ends_at <= starts_at
      errors.add(:ends_at, "must be later than the start time")
    end
  end
end