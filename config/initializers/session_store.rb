if Rails.env.production?
  Rails.application.config.session_store(
    :cookie_store,
    key: "_secure_my_slot_session",
    domain: ".securemyslot.co.uk",
    same_site: :lax,
    secure: true
  )
else
  Rails.application.config.session_store(
    :cookie_store,
    key: "_secure_my_slot_session",
    same_site: :lax,
    secure: false
  )
end