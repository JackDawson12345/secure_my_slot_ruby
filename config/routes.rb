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
  # thisisatest.lvh.me:3000
  constraints BusinessSubdomainConstraint do
    root to: "business_sites#show", as: "business_site"
  end


  # API
  namespace :api do
    namespace :v1 do

      namespace :business do
        get "dashboard", to: "dashboard#show"
      end

      namespace :customer do
        get "dashboard", to: "dashboard#show"
      end


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
  resources :bookings, only: [:create] do
    member do
      get :payment_success
    end
  end

  get "/booking_slots", to: "bookings#slots"


  # Public website pages
  get "businesses",
      to: "pages/website#businesses"

  get "categories",
      to: "pages/website#categories"

  get "businesses/:id",
      to: "pages/business_website#index"


  # Customer account
  namespace :account do

    get "dashboard",
        to: "dashboard#index",
        as: :dashboard

    get "dashboard/bookings",
        to: "bookings#index",
        as: :bookings

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

    get "dashboard/bookings/add-booking",
        to: "bookings#add_booking",
        as: :add_booking

    post "dashboard/bookings/add-booking",
         to: "bookings#create"

    get "dashboard/bookings/:id",
        to: "bookings#show",
        as: :booking

    get "dashboard/customers",
        to: "customers#index",
        as: :customers


    resources :services,
              path: "dashboard/services"


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


    get "dashboard/settings",
        to: "settings#index",
        as: :settings

    patch "dashboard/settings",
          to: "settings#update"

    get "dashboard/website-settings",
        to: "website_settings#index",
        as: :website_settings

    patch "dashboard/website-settings",
          to: "website_settings#update"

    patch "dashboard/password",
          to: "settings#update_password",
          as: :password

    delete "dashboard/settings/logo",
           to: "settings#destroy_logo",
           as: :settings_logo

    get "dashboard/payments",
        to: "payments#index",
        as: :payments

    post "dashboard/payments/connect",
         to: "payments#connect",
         as: :payments_connect

    get "dashboard/payments/return",
        to: "payments#stripe_return",
        as: :payments_return

    get "dashboard/payments/refresh",
        to: "payments#stripe_refresh",
        as: :payments_refresh

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