class OrderHold < ApplicationRecord

  belongs_to :business
  belongs_to :user
  belongs_to :order, optional: true

end