class Agreement < ApplicationRecord
  belongs_to :business

  validates :name, presence: true
  validates :content, presence: true
end
