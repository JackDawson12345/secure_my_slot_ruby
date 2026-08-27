module ApplicationHelper
  BUSINESS_CATEGORIES = {
    "barber" => "Barber",
    "hairdresser" => "Hairdresser",
    "beauty_and_nails" => "Beauty and Nails",
    "personal_trainer" => "Personal Trainer",
    "coach" => "Coach",
    "tutor" => "Tutor",
    "consultant" => "Consultant",
    "therapist" => "Therapist",
    "massage_professional" => "Massage Professional",
    "photographer" => "Photographer",
    "cleaner" => "Cleaner",
    "tradesperson" => "Tradesperson",
    "mobile_service" => "Mobile Service",
    "repair_service" => "Repair Service",
    "other" => "Other"
  }.freeze

  def business_category_name(category)
    BUSINESS_CATEGORIES[category] || category&.humanize
  end
end
