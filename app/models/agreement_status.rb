class AgreementStatus < ApplicationRecord

  belongs_to :business
  belongs_to :booking
  belongs_to :agreement

  has_many_attached :signatures

end