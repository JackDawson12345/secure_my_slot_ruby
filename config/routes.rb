Rails.application.routes.draw do

  get "business_sites/show"

  devise_for :users,
             path: "",
             path_names: {
               sign_in: "login",
               sign_out: "logout",
               registration: "",
               sign_up: "sign-up"
             }


  # Business subdomains
  # Example:
  # thisisatest..securemyslot.co.uk
  constraints BusinessSubdomainConstraint do
    root to: "business_sites#show", as: "business_site"

    get "/consultation-form",
        to: "business_sites#consultation_form",
        as: :business_site_consultation_form

    post "/consultation-form",
         to: "business_sites#submit_consultation_form",
         as: :submit_business_site_consultation_form

    get "/agreement-form",
        to: "business_sites#agreement_form",
        as: :business_site_agreement_form

    post "/agreement-form",
         to: "business_sites#submit_agreement_form",
         as: :submit_business_site_agreement_form

    post "/check-service-coupon",
         to: "business_sites#check_service_coupon",
         as: :check_service_coupon

    get "/shop",
        to: "business_sites#shop",
        as: :business_site_shop

    get "/shop/:slug",
        to: "business_sites#product",
        as: :business_site_product

    get "/cart",
        to: "business_sites#cart",
        as: :business_site_cart

    post "/cart/add",
         to: "business_sites#add_to_cart",
         as: :add_to_cart

    patch "/cart/update",
          to: "business_sites#update_cart",
          as: :update_cart

    delete "/cart/remove/:id",
           to: "business_sites#remove_from_cart",
           as: :remove_from_cart

    get "/checkout",
        to: "business_sites#checkout",
        as: :business_site_checkout

    post "/order/create",
         to: "business_sites#create_order",
         as: :create_order

    get "/orders/:public_id",
        to: "business_sites#order_confirmation",
        as: :order_confirmation

    get "/order/payment/:id",
        to: "business_sites#payment_success",
        as: :order_payment_success
  end


  match "/500", to: "errors#internal_server_error", via: :all
  match "/404", to: "errors#not_found", via: :all


  # API
  namespace :api do
    namespace :v1 do

      post "forgot_password", to: "passwords#create"
      patch "reset_password", to: "passwords#update"

      namespace :business do
        get "dashboard", to: "dashboard#show"
        get "get-dashboard-details/:id", to: "get_info#get_dashboard_details"

        get "get-businesses",
            to: "get_info#get_businesses"
        get "get-users-business/:user_id",
            to: "get_info#get_users_business"

        get "calendar-sync",
            to: "calendar_sync#show"
        get "calendar-sync/connect",
            to: "calendar_sync#connect"
        get "calendar-sync/callback",
            to: "calendar_sync#callback"
        post "calendar-sync/sync",
             to: "calendar_sync#sync"
        delete "calendar-sync",
               to: "calendar_sync#disconnect"

        get "/:id",
            to: "get_info#get_business",
            constraints: { id: /\d+/ }

        get "/:id/get-reviews",
            to: "get_info#get_reviews"

        get "/:id/business-settings",
            to: "get_info#get_business_settings"

        get "/:id/bookings",
            to: "bookings#get_bookings"
        get "/:id/booking/:booking_id",
            to: "bookings#get_booking"
        patch "/:id/booking/:booking_id",
              to: "bookings#update_status"
        get "/:id/get-booking-slots",
            to: "bookings#get_booking_slots"
        post ":id/create-booking",
             to: "bookings#create"

        get "/:id/services",
            to: "services#get_services"
        get "/:id/service/:service_id",
            to: "services#get_service"
        patch "/:id/service/:service_id",
              to: "services#update_service"
        post "/:id/services",
             to: "services#create_service"

        get "/:id/get-opening-hours",
            to: "opening_hours#get_opening_hours"
        patch "/:id/update-opening-hours",
              to: "opening_hours#update_opening_hours"

        get ":id/blocked-times",
            to: "opening_hours#get_blocked_times"
        post ":id/blocked-times",
             to: "opening_hours#create_blocked_time"
        patch ":id/blocked-times/:blocked_time_id",
              to: "opening_hours#update_blocked_time"
        delete ":id/blocked-times/:blocked_time_id",
               to: "opening_hours#delete_blocked_time"

        get "/:id/get_customers",
            to: "customers#get_customers"
        get "/:id/get-customer/:customer_id",
            to: "customers#get_customer"

        get ":id/settings",
            to: "settings#show"
        patch ":id/settings",
              to: "settings#update"
        patch ":id/settings/password",
              to: "settings#update_password"

        get "/:id/payments",
            to: "payments#index",
            as: :payments
        post "/:id/payments/connect",
             to: "payments#connect",
             as: :payments_connect
        get "/:id/payments/status",
            to: "payments#status",
            as: :payments_status
        post "/:id/payments/refresh",
             to: "payments#refresh",
             as: :payments_refresh

        get "/:id/payments/stripe-return",
            to: "payments#stripe_return",
            as: :payments_stripe_return
        get "/:id/payments/stripe-refresh",
            to: "payments#stripe_refresh",
            as: :payments_stripe_refresh



        get ":id/website-settings",
            to: "website_settings#show"
        patch ":id/website-settings",
              to: "website_settings#update"

      end

      namespace :customer do
        get "dashboard",
            to: "dashboard#show"

        get "/:id/get-dashboard-details",
            to: "get_info#get_dashboard_details"

        get "/:id/booking/:booking_id",
            to: "bookings#get_booking"

        get "/:id/bookings",
            to: "bookings#get_bookings"

        patch ":id/bookings/:booking_id/reschedule",
              to: "bookings#reschedule"

        patch ":id/bookings/:booking_id/cancel",
              to: "bookings#cancel"

        get "/:id/settings",
            to: "settings#show"

        patch "/:id/settings",
              to: "settings#update"

        patch "/:id/settings/password",
              to: "settings#update_password"
      end

      get '/:id/get-businesses',
          to: "businesses#get_businesses"
      get '/:id/get-business/:business_id',
          to: "businesses#get_business"

      post "customer/:id/business/:business_id/create-booking",
           to: "businesses#create_customer_booking"

      get "customer/:id/booking-holds/:booking_hold_id/payment-success",
          to: "businesses#customer_payment_success"

      get "customer/:id/booking-holds/:booking_hold_id/payment-cancelled",
          to: "businesses#customer_payment_cancelled"



      devise_scope :user do
        post "sign_up",
             to: "registrations#create",
             defaults: { format: :json }

        post "login",
             to: "sessions#create",
             defaults: { format: :json }

        delete "logout",
               to: "sessions#destroy",
               defaults: { format: :json }
      end


      get "me",
          to: "users#show",
          defaults: { format: :json }

    end
  end


  # Main website
  # Example:
  # riverboat-canyon-expensive.ngrok-free.dev
  root "pages/website#home"
  resources :bookings, only: [:create]

  post "stripe/webhook",
       to: "stripe_webhooks#create",
       as: :stripe_webhook

  get "payment-success/:id",
      to: "pages/website#payments_success",
      as: :payment_success

  get "/booking_slots",
      to: "bookings#slots"

  # Normal/free booking confirmation
  get "/bookings/:id/confirmation",
      to: "bookings#confirmation",
      as: :booking_confirmation

  get "/booking-holds/:id/payment-success",
      to: "bookings#payment_success",
      as: :payment_success_booking_hold

  post "/stripe/webhook",
       to: "stripe_webhooks#create"


  # Public website pages
  get "businesses",
      to: "pages/website#businesses"

  get "about-us",
      to: "pages/website#about_us"

  get "contact-us",
      to: "pages/website#contact_us"
  post "/contact", to: "pages/website#create"

  get "privacy-policy",
      to: "pages/website#privacy_policy"

  get "terms-of-use",
      to: "pages/website#terms_of_use"

  get "features",
      to: "pages/website#features"


  # Customer account
  namespace :account do

    get "dashboard",
        to: "dashboard#index",
        as: :dashboard

    get "dashboard/bookings",
        to: "bookings#index",
        as: :bookings
    get "dashboard/bookings/:id",
        to: "bookings#show",
        as: :show_booking
    get "dashboard/bookings/:id/consultation-pdf",
        to: "bookings#consultation_pdf",
        as: :booking_consultation_pdf
    patch "dashboard/bookings/:id/upload-images",
          to: "bookings#upload_images",
          as: :upload_booking_images
    patch "dashboard/bookings/:id/remove-image/:image_id",
          to: "bookings#remove_image",
          as: :remove_booking_image

    get "dashboard/bookings/:id/reschedule",
        to: "bookings#reschedule",
        as: :reschedule_booking
    get "dashboard/bookings/:id/reschedule/slots",
        to: "bookings#reschedule_slots",
        as: :reschedule_booking_slots
    patch "dashboardbookings/:id/cancel",
          to: "bookings#cancel",
          as: :cancel_booking
    patch "/dashboard/bookings/:id/reschedule",
          to: "bookings#update_reschedule",
          as: :update_reschedule_booking

    get "dashboard/booking-history",
        to: "booking_history#index",
        as: :booking_history

    resource :settings, path: "dashboard/settings", only: [:update]
    get "dashboard/settings", to: "settings#show", as: :account_settings

    patch "dashboard/settings",
          to: "settings#update"

    get "dashboard/book-appointment",
        to: "book_appointment#index",
        as: :book_appointment

    get "orders",
        to: "orders#index",
        as: :orders

    get "orders/:id",
        to: "orders#show",
        as: :order

  end


  # Business portal
  scope path: "business",
        module: "business_portal",
        as: "business" do


    get "sign-up",
        to: "sign_up#index",
        as: :sign_up

    post "sign-up",
         to: "sign_up#create"

    get "sign-up/check-page-address",
        to: "sign_up#check_page_address",
        as: :check_business_page_address

    get "subscription",
        to: "subscription#index",
        as: :subscription


    get "dashboard",
        to: "dashboard#index",
        as: :dashboard

    get "dashboard/bookings",
        to: "bookings#index",
        as: :bookings

    get "dashboard/bookings/calendar",
        to: "bookings#calendar",
        as: :bookings_calendar

    get "dashboard/bookings/find",
        to: "bookings#find",
        as: :bookings_find

    get "dashboard/bookings/add-booking",
        to: "bookings#add_booking",
        as: :add_booking

    post "dashboard/bookings/add-booking",
         to: "bookings#create"

    get "dashboard/bookings/:id",
        to: "bookings#show",
        as: :booking

    get "businesses/bookings/:id/agreements/:token",
        to: "bookings#agreements_show",
        as: :booking_agreement_show

    get "businesses/bookings/:id/agreements/:token/pdf",
        to: "bookings#agreements_pdf",
        as: :agreement_pdf

    get "bookings/:id/consultation-pdf",
        to: "bookings#consultation_pdf",
        as: :booking_consultation_pdf

    patch "dashboard/bookings/:id/status",
          to: "bookings#update_status",
          as: :booking_status

    patch "dashboard/bookings/:id/create-payment-link",
        to: "bookings#create_payment_link",
        as: :create_payment_link

    get "dashboard/bookings/:id/payment-link",
          to: "bookings#payment_link",
          as: :payment_link

    patch "dashboard/bookings/:id/payment-link/send_email",
        to: "bookings#send_payment_link_email",
        as: :payment_link_send_email

    patch "dashboard/bookings/:id/payment-link/send_sms",
          to: "bookings#send_payment_link_sms",
          as: :payment_link_send_sms

    get "dashboard/bookings/:id/no-show-fee",
          to: "bookings#no_show",
          as: :no_show

    post "dashboard/bookings/:id/no-show-fee",
         to: "bookings#charge_no_show_fee",
         as: :charge_no_show_fee

    patch "dashboard/bookings/:id/mark-as-paid",
        to: "bookings#mark_as_paid",
        as: :mark_as_paid

    get "dashboard/customers",
        to: "customers#index",
        as: :customers

    get "dashboard/customers/:id",
        to: "customers#show",
        as: :customer_show


    resources :service_categories,
              path: "dashboard/services/categories",
              except: [:show],
              as: :service_categories

    resources :service_coupons,
              path: "dashboard/services/coupons" do

    end

    resources :services,
              path: "dashboard/services" do
      delete :remove_image, on: :member
    end

    resources :products,
              path: "dashboard/products" do

      get "orders",
          on: :collection,
          to: "products#orders",
          as: :orders

      get "orders/:id",
          on: :collection,
          to: "products#order",
          as: :order

      patch "orders/:id/update_status",
            to: "products#update_status",
            as: :update_status

    end


    get "dashboard/opening-hours",
        to: "opening_hours#index",
        as: :opening_hours

    patch "dashboard/opening-hours",
          to: "opening_hours#update"

    get "dashboard/opening-hours/block-time",
        to: "blocked_times#index",
        as: :blocked_times

    post "dashboard/opening-hours/block-time",
         to: "blocked_times#create",
         as: :create_blocked_time

    get "dashboard/opening-hours/block-time/:id/edit",
        to: "blocked_times#edit",
        as: :edit_blocked_time

    patch "dashboard/opening-hours/block-time/:id",
          to: "blocked_times#update",
          as: :blocked_time

    delete "dashboard/opening-hours/block-time/:id",
           to: "blocked_times#destroy",
           as: :delete_blocked_time

    get "dashboard/settings/",
        to: "settings#index",
        as: :settings

    get "dashboard/settings/general-settings",
        to: "settings#general_settings",
        as: :general_settings

    get "dashboard/settings/calendar-sync",
        to: "settings#calendar_sync",
        as: :calendar_sync

    get "dashboard/settings/consultation-form",
        to: "settings#consultation_form",
        as: :consultation_form

    patch "dashboard/settings/consultation-form",
          to: "settings#update_consultation_form",
          as: :update_consultation_form

    get "dashboard/settings/calendar-sync/google",
        to: "calendar_connections#google",
        as: :google_calendar_connect

    get "dashboard/settings/calendar-sync/google/callback",
        to: "calendar_connections#callback",
        as: :google_calendar_callback

    get "dashboard/settings/calendar-sync/google/sync",
        to: "calendar_connections#sync",
        as: :google_calendar_sync

    delete "dashboard/settings/calendar-sync/google",
           to: "calendar_connections#disconnect",
           as: :google_calendar_disconnect

    get "dashboard/settings/email-templates",
        to: "settings#email_templates",
        as: :email_templates

    get "dashboard/settings/email-templates/:template_type",
        to: "settings#email_templates_edit",
        as: :email_templates_edit

    patch "dashboard/settings/email-templates/:template_type",
          to: "settings#update_email_template",
          as: :update_email_template

    patch "dashboard/settings",
          to: "settings#update"

    get "dashboard/settings/website-settings",
        to: "website_settings#index",
        as: :website_settings

    patch "dashboard/settings/website-settings/content",
          to: "website_content_settings#update",
          as: :website_content_settings


    patch "dashboard/settings/website-settings/colour",
          to: "website_colour_settings#update",
          as: :website_colour_settings


    post "dashboard/settings/website-settings/generate-colours",
         to: "website_colour_settings#generate_colours",
         as: :generate_website_colours

    patch "dashboard/settings/website-settings/gallery",
          to: "website_gallery_settings#update",
          as: :website_gallery_settings

    delete "dashboard/settings/website-settings/gallery/:id",
           to: "website_gallery_settings#destroy",
           as: :destroy_gallery_image

    patch "dashboard/password",
          to: "settings#update_password",
          as: :password

    delete "dashboard/settings/logo",
           to: "settings#destroy_logo",
           as: :settings_logo

    delete "dashboard/settings/favicon",
           to: "settings#remove_favicon",
           as: :settings_favicon

    get "dashboard/settings/payments",
        to: "payments#index",
        as: :payments

    get "dashboard/settings/payments/stripe",
        to: "payments#stripe",
        as: :payments_stripe

    post "dashboard/settings/payments/stripe/connect",
         to: "payments#connect",
         as: :payments_connect

    get "dashboard/settings/payments/stripe/return",
        to: "payments#stripe_return",
        as: :payments_return

    get "dashboard/settings/payments/stripe/refresh",
        to: "payments#stripe_refresh",
        as: :payments_refresh

    delete "dashboard/settings/payments/stripe/disconnect",
           to: "payments#disconnect",
           as: :payments_disconnect

    get "dashboard/settings/qr-code/download", to: "settings#download", as: :download_qr_code

    get "dashboard/settings/birthday-reminder",
        to: "settings#birthday_reminder",
        as: :birthday_reminder
    patch "dashboard/settings/birthday-reminder",
          to: "settings#update_birthday_reminder",
          as: :update_birthday_reminder

    resources :agreements,
              path: 'dashboard/settings/agreements',
              only: [:index, :new, :create, :edit, :update, :destroy]

    patch "dashboard/settings/agreements/send_agreement/:id",
          to: "agreements#send_agreement",
          as: :send_agreement

    get "/dashboard/reports",
        to: "reports#index",
        as: :reports

    get "/dashboard/reports/booking-reports",
        to: "reports#booking",
        as: :booking_reports

    get "/dashboard/reports/revenue-reports",
        to: "reports#revenue",
        as: :revenue_reports

    get "/dashboard/reports/customer-reports",
        to: "reports#customer",
        as: :customer_reports

    get "/dashboard/reports/service-reports",
        to: "reports#service",
        as: :service_reports

    get "/dashboard/reports/staff-reports",
        to: "reports#staff",
        as: :staff_reports

    get "/dashboard/reports/website-reports",
        to: "reports#website",
        as: :website_reports

    get "/dashboard/social-media",
        to: "social_media#index",
        as: :social_media

    get "/dashboard/social-media/new",
        to: "social_media#new",
        as: :new_social_media_post

    post "/dashboard/social-media",
         to: "social_media#create",
         as: :create_social_media_post

    get "/dashboard/social-media/:id/edit",
        to: "social_media#edit",
        as: :edit_social_media_post

    get "/dashboard/social-media/:id",
        to: "social_media#show",
        as: :show_social_media_post

    post "/dashboard/social-media/:id/generate-caption",
         to: "social_media#generate_caption",
         as: :generate_social_media_caption

    post "/dashboard/social-media/:id/generate-hashtags",
         to: "social_media#generate_hashtags",
         as: :generate_social_media_hashtags

    patch "/dashboard/social-media/:id",
          to: "social_media#update",
          as: :update_social_media_post

    patch "/dashboard/social-media/:id/duplicate",
          to: "social_media#duplicate",
          as: :duplicate_social_media_post




  end

  # Admin
  namespace :admin do

    get "dashboard",
        to: "dashboard#index",
        as: :dashboard

    scope "dashboard" do
      resources :customers, only: %i[index show new create] do
        resources :services,
                  controller: "customer_services",
                  except: %i[index show]

        resource :opening_hours,
                 controller: "customer_opening_hours",
                 only: %i[edit update]

        resource :website_settings,
                 controller: "customer_website_settings",
                 only: %i[edit update]

        resource :settings,
                 controller: "customer_settings",
                 only: %i[edit update]
      end

      get "settings",
          to: "settings#index",
          as: :settings

      patch "settings",
            to: "settings#update"

      patch "password",
            to: "settings#update_password",
            as: :password
    end

  end

end