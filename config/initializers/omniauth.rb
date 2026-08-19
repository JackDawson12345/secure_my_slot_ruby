Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id),
           Rails.application.credentials.dig(:google, :client_secret),
           {
             scope: "calendar.readonly",
             prompt: "consent",
             access_type: "offline"
           }
end