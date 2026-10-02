class ServiceAgent < ApplicationRecord
  belongs_to :service
  belongs_to :business_agent
end
