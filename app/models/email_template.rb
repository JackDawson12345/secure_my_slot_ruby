class EmailTemplate < ApplicationRecord
  belongs_to :business

  TEMPLATE_TYPES = %w[confirmation reminder].freeze

  validates :template_type,
            presence: true,
            inclusion: { in: TEMPLATE_TYPES }

  validates :template_type,
            uniqueness: { scope: :business_id }
end
