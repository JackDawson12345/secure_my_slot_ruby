class BusinessBlockedTime < ApplicationRecord
  belongs_to :business

  attr_accessor :date,
                :end_date,
                :start_time,
                :end_time

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validate :ends_after_start
  validate :does_not_overlap_existing_block

  scope :upcoming, lambda {
    where("ends_at >= ?", Time.current)
      .order(:starts_at)
  }

  scope :past, lambda {
    where("ends_at < ?", Time.current)
      .order(starts_at: :desc)
  }

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "must be after the start time")
  end

  def does_not_overlap_existing_block
    return if starts_at.blank? || ends_at.blank? || business.blank?

    overlap =
      business.business_blocked_times
              .where.not(id: id)
              .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
              .exists?

    return unless overlap

    errors.add(:base, "This blocked time overlaps another blocked period")
  end
end