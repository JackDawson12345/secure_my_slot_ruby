class BusinessSubdomainConstraint

  EXCLUDED_SUBDOMAINS = %w[
    riverboat-canyon-expensive
    www
    api
  ].freeze

  def self.matches?(request)
    request.subdomain.present? &&
      !EXCLUDED_SUBDOMAINS.include?(request.subdomain)
  end

end