class EmailTemplate < ApplicationRecord
  belongs_to :business


  has_many_attached :attachments

  validates :template_type,
            presence: true

  validates :template_type,
            uniqueness: { scope: :business_id }
end
