class CustomEmailTemplateStatus < ApplicationRecord
  belongs_to :business
  belongs_to :booking
  belongs_to :email_template
end
