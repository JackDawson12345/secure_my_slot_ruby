class BusinessSubdomainConstraint
  EXCLUDED_SUBDOMAINS = %w[
    riverboat-canyon-expensive
    secure-my-slot-5b52497b10fa
    securemyslot
    securemyslot.co.uk
    www
    api
  ].freeze

  def self.matches?(request)
    subdomain = request.subdomain

    return false if subdomain.blank?
    return false if EXCLUDED_SUBDOMAINS.include?(subdomain)

    Business.exists?(page_address: subdomain)
  end
end