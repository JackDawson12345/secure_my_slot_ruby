class AgreementSignature < ApplicationRecord
  belongs_to :agreement_status

  has_one_attached :image
end
