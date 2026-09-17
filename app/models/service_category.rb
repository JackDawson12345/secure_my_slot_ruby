class ServiceCategory < ApplicationRecord
  belongs_to :business
  has_many :services

  validates :name, presence: true
end
