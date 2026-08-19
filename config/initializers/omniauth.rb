Rails.application.config.middleware.use OmniAuth::Builder do

  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"] || Rails.application.credentials.dig(:google, :client_id),
           ENV["GOOGLE_CLIENT_SECRET"] || Rails.application.credentials.dig(:google, :client_secret),
           {
             scope: "calendar.readonly",
             prompt: "consent",
             access_type: "offline"
           }

end