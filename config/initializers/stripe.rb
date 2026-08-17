# config/initializers/stripe.rb
Stripe.api_key =
  ENV["STRIPE_SECRET_KEY"].presence ||
  Rails.application.credentials.dig(:stripe, :secret_key)