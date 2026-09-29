class ServiceTime < ApplicationRecord
  belongs_to :service

  validates :start_time, presence: true
  validates :end_time, presence: true

  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after the start time")
    end
  end
end