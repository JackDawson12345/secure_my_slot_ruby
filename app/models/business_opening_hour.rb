class BusinessOpeningHour < ApplicationRecord
  belongs_to :business, inverse_of: :opening_hours

  has_many :breaks,
           class_name: "BusinessOpeningHourBreak",
           dependent: :destroy,
           inverse_of: :business_opening_hour

  accepts_nested_attributes_for :breaks,
                                allow_destroy: true,
                                reject_if: :all_blank

  enum :day_of_week, {
    monday: 0,
    tuesday: 1,
    wednesday: 2,
    thursday: 3,
    friday: 4,
    saturday: 5,
    sunday: 6
  }

  validates :day_of_week, presence: true
  validates :day_of_week, uniqueness: { scope: :business_id }

  validates :opens_at, presence: true, if: :open?
  validates :closes_at, presence: true, if: :open?

  validate :closing_time_after_opening_time
  validate :breaks_are_within_opening_hours

  before_validation :clear_times_when_closed

  def day_name
    day_of_week.humanize
  end

  def duration_minutes
    return 0 unless open? && opens_at.present? && closes_at.present?

    total = minutes_between(opens_at, closes_at)

    break_minutes = breaks.reject(&:marked_for_destruction?).sum do |break_record|
      next 0 unless break_record.starts_at.present? && break_record.ends_at.present?

      minutes_between(break_record.starts_at, break_record.ends_at)
    end

    [total - break_minutes, 0].max
  end

  private

  def clear_times_when_closed
    return if open?

    self.opens_at = nil
    self.closes_at = nil

    breaks.each(&:mark_for_destruction)
  end

  def closing_time_after_opening_time
    return unless open?
    return if opens_at.blank? || closes_at.blank?

    if closes_at <= opens_at
      errors.add(:closes_at, "must be later than the opening time")
    end
  end

  def breaks_are_within_opening_hours
    return unless open?
    return if opens_at.blank? || closes_at.blank?

    breaks.reject(&:marked_for_destruction?).each do |break_record|
      next if break_record.starts_at.blank? || break_record.ends_at.blank?

      unless break_record.starts_at >= opens_at &&
             break_record.ends_at <= closes_at
        errors.add(
          :base,
          "#{day_name} breaks must be within the opening hours"
        )
      end
    end
  end

  def minutes_between(start_time, end_time)
    start_minutes = (start_time.hour * 60) + start_time.min
    end_minutes = (end_time.hour * 60) + end_time.min

    end_minutes - start_minutes
  end
end