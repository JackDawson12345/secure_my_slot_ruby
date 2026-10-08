module Api
  module V1
    class BusinessesController < ApplicationController
      skip_before_action :verify_authenticity_token

      # ============================================================
      # GET BUSINESSES
      # ============================================================

      def get_businesses
        customer =
          ::User.find(params[:id])

        # ==========================================================
        # FILTER VALUES
        # ==========================================================

        search =
          params[:search]
            .to_s
            .strip
            .downcase

        categories =
          Array(params[:category])
            .reject(&:blank?)

        sort =
          params[:sort]
            .presence ||
          "best_match"

        page =
          params[:page]
            .to_i

        businesses_per_page =
          params[:businesses_per_page]
            .to_i

        page =
          1 if page <= 0

        businesses_per_page =
          10 if businesses_per_page <= 0

        # ==========================================================
        # DISTANCE
        # ==========================================================
        #
        # Web slider:
        #
        # 0 = 5 miles
        # 1 = 10 miles
        # 2 = 25 miles
        # 3 = 50 miles
        # 4 = 100 miles
        # 5 = Unlimited
        #
        # If Expo later sends an actual mileage number rather than
        # the slider index, values above 5 are treated as miles.
        # ==========================================================

        distance_limit =
          distance_limit_from_param(
            params[:distance]
          )

        needs_distance =
          params[:distance_to_customer] == "true" ||
          distance_limit.present? ||
          sort == "distance"

        # ==========================================================
        # START WITH ALL BUSINESSES
        # ==========================================================

        businesses =
          ::Business
            .includes(
              :business_setting,
              :services
            )
            .order(
              created_at: :desc
            )
            .to_a

        # ==========================================================
        # SEARCH
        # ==========================================================

        if search.present?
          businesses =
            businesses.select do |business|
              settings =
                business.business_setting

              next false unless settings

              business_name =
                settings.business_name
                        .to_s
                        .downcase

              category =
                settings.business_category
                        .to_s
                        .downcase

              address =
                [
                  settings.address_line_1,
                  settings.address_line_2,
                  settings.town_or_city,
                  settings.postcode,
                  settings.country
                ]
                  .compact
                  .join(" ")
                  .downcase

              service_names =
                business
                  .services
                  .map(&:name)
                  .compact
                  .join(" ")
                  .downcase

              business_name.include?(search) ||
                category.include?(search) ||
                address.include?(search) ||
                service_names.include?(search)
            end
        end

        # ==========================================================
        # MULTIPLE CATEGORY FILTER
        # ==========================================================

        if categories.any?
          businesses =
            businesses.select do |business|
              category =
                business
                  .business_setting
                  &.business_category
                  .to_s

              categories.include?(
                category
              )
            end
        end

        # ==========================================================
        # BUILD FULL BUSINESS DATA
        #
        # We do this BEFORE pagination because distance,
        # availability and soonest sorting all need to work across
        # the complete filtered result set.
        # ==========================================================

        business_results =
          businesses.filter_map do |business|
            business_settings =
              business.business_setting

            next unless business_settings

            services =
              business.services

            opening_hours =
              ::BusinessOpeningHour
                .where(
                  business_id:
                    business.id
                )
                .to_a

            # --------------------------------------------------------
            # Ensure coordinates exist
            # --------------------------------------------------------

            if business_settings.latitude.nil? ||
               business_settings.longitude.nil?

              coordinates =
                geocode_business_address(
                  business_settings
                )

              if coordinates
                business_settings.update(
                  latitude:
                    coordinates[:latitude],

                  longitude:
                    coordinates[:longitude]
                )
              end
            end

            # --------------------------------------------------------
            # Next available slot
            # --------------------------------------------------------

            next_slot =
              BusinessNextAvailableSlot
                .new(business)
                .call

            # --------------------------------------------------------
            # Distance
            # --------------------------------------------------------

            distance =
              if needs_distance
                begin
                  business.distance_to_customer(
                    customer
                  )
                rescue StandardError => e
                  Rails.logger.warn(
                    "Unable to calculate distance for " \
                      "business #{business.id}: " \
                      "#{e.class} - #{e.message}"
                  )

                  nil
                end
              end

            # --------------------------------------------------------
            # Open today
            # --------------------------------------------------------

            open_today =
              business_open_today?(
                opening_hours
              )

            # --------------------------------------------------------
            # Subscription
            # --------------------------------------------------------

            subscription_level =
              business.subscription_level

            premium =
              %w[
          pro
          pro_plus
        ].include?(
                subscription_level.to_s
              )

            # --------------------------------------------------------
            # Logo
            # --------------------------------------------------------

            logo_url =
              business_logo_url(
                business_settings
              )

            # --------------------------------------------------------
            # Response
            # --------------------------------------------------------

            {
              details: {
                id:
                  business.id,

                business_name:
                  business_settings.business_name,

                business_category:
                  business_settings.business_category,

                phone_number:
                  business_settings.phone_number,

                business_email:
                  business_settings.business_email,

                business_description:
                  business_settings.business_description,

                page_address:
                  business.page_address,

                subscription_level:
                  subscription_level,

                premium:
                  premium,

                open_today:
                  open_today,

                logo_url:
                  logo_url,

                address: {
                  address_line_1:
                    business_settings.address_line_1,

                  address_line_2:
                    business_settings.address_line_2,

                  town_or_city:
                    business_settings.town_or_city,

                  postcode:
                    business_settings.postcode,

                  country:
                    business_settings.country
                },

                booking_page_live:
                  business_settings.booking_page_live,

                automatically_confirm_bookings:
                  business_settings
                    .automatically_confirm_bookings,

                allow_customer_cancellations:
                  business_settings
                    .allow_customer_cancellations,

                require_customer_phone_number:
                  business_settings
                    .require_customer_phone_number,

                cancellation_notice_hours:
                  business_settings
                    .cancellation_notice_hours,

                new_booking_notifications:
                  business_settings
                    .new_booking_notifications,

                cancellation_notifications:
                  business_settings
                    .cancellation_notifications,

                daily_appointment_summary:
                  business_settings
                    .daily_appointment_summary,

                latitude:
                  business_settings.latitude,

                longitude:
                  business_settings.longitude,

                created_at:
                  business_settings.created_at,

                updated_at:
                  business_settings.updated_at
              },

              services:
                services.map do |service|
                  {
                    id:
                      service.id,

                    name:
                      service.name,

                    description:
                      service.description,

                    price:
                      service.price,

                    minutes_duration:
                      service.minutes_duration,

                    status:
                      service.status,

                    deposit_enabled:
                      service.deposit_enabled,

                    deposit:
                      service.deposit,

                    icon:
                      service.icon,

                    created_at:
                      service.created_at,

                    updated_at:
                      service.updated_at
                  }
                end,

              opening_hours:
                opening_hours.map do |opening_hour|
                  {
                    id:
                      opening_hour.id,

                    day_of_week:
                      opening_hour.day_of_week,

                    open:
                      opening_hour.open,

                    opens_at:
                      opening_hour.opens_at,

                    closes_at:
                      opening_hour.closes_at,

                    created_at:
                      opening_hour.created_at,

                    updated_at:
                      opening_hour.updated_at
                  }
                end,

              next_slot:
                next_slot ? {
                  date:
                    next_slot[:date],

                  time:
                    next_slot[:time],

                  service: {
                    id:
                      next_slot[:service].id,

                    name:
                      next_slot[:service].name,

                    description:
                      next_slot[:service]
                        .description,

                    price:
                      next_slot[:service].price,

                    minutes_duration:
                      next_slot[:service]
                        .minutes_duration,

                    status:
                      next_slot[:service]
                        .status,

                    deposit_enabled:
                      next_slot[:service]
                        .deposit_enabled,

                    deposit:
                      next_slot[:service]
                        .deposit,

                    icon:
                      next_slot[:service].icon,

                    created_at:
                      next_slot[:service]
                        .created_at,

                    updated_at:
                      next_slot[:service]
                        .updated_at
                  }
                } : nil,

              distance_to_customer:
                distance
            }
          end

        # ==========================================================
        # DISTANCE FILTER
        # ==========================================================

        if distance_limit.present?
          business_results =
            business_results.select do |business|
              distance =
                business[
                  :distance_to_customer
                ]

              distance.present? &&
                distance.to_f <=
                  distance_limit
            end
        end

        # ==========================================================
        # AVAILABLE TODAY
        # ==========================================================

        if ActiveModel::Type::Boolean.new.cast(
          params[:available_today]
        )

          business_results =
            business_results.select do |business|
              slot =
                business[:next_slot]

              next false unless slot

              slot_date =
                slot[:date].to_date

              slot_date ==
                Date.current
            end
        end

        # ==========================================================
        # AVAILABLE THIS WEEK
        # ==========================================================

        if ActiveModel::Type::Boolean.new.cast(
          params[:available_this_week]
        )

          business_results =
            business_results.select do |business|
              slot =
                business[:next_slot]

              next false unless slot

              slot_date =
                slot[:date].to_date

              slot_date >=
                Date.current &&
                slot_date <=
                  Date.current.end_of_week
            end
        end

        # ==========================================================
        # SORTING
        # ==========================================================

        case sort
        when "distance"
          business_results.sort_by! do |business|
            distance =
              business[
                :distance_to_customer
              ]

            distance.present? ?
              distance.to_f :
              Float::INFINITY
          end

        when "soonest"
          business_results.sort_by! do |business|
            slot =
              business[:next_slot]

            next Float::INFINITY unless slot

            next_slot_sort_value(
              slot
            )
          end

        else
          # --------------------------------------------------------
          # BEST MATCH
          #
          # Premium businesses first.
          # Then businesses with availability.
          # Then newest businesses.
          # --------------------------------------------------------

          business_results.sort_by! do |business|
            [
              business.dig(
                :details,
                :premium
              ) ? 0 : 1,

              business[:next_slot]
                .present? ? 0 : 1,

              -business
                 .dig(
                   :details,
                   :created_at
                 )
                 .to_time
                 .to_i
            ]
          end
        end

        # ==========================================================
        # PAGINATION
        # ==========================================================

        total_businesses =
          business_results.length

        total_pages =
          (
            total_businesses.to_f /
              businesses_per_page
          ).ceil

        total_pages =
          1 if total_pages.zero?

        page =
          total_pages if page >
                         total_pages

        offset =
          (page - 1) *
          businesses_per_page

        paginated_businesses =
          business_results.slice(
            offset,
            businesses_per_page
          ) || []

        # ==========================================================
        # RESPONSE
        # ==========================================================

        render json: {
          total_businesses:
            total_businesses,

          businesses_per_page:
            businesses_per_page,

          current_page:
            page,

          total_pages:
            total_pages,

          filters: {
            search:
              params[:search],

            category:
              categories,

            distance:
              params[:distance],

            available_today:
              ActiveModel::Type::Boolean
                .new
                .cast(
                  params[:available_today]
                ),

            available_this_week:
              ActiveModel::Type::Boolean
                .new
                .cast(
                  params[
                    :available_this_week
                  ]
                ),

            sort:
              sort
          },

          businesses:
            paginated_businesses
        }, status: :ok
      end


      # ============================================================
      # GET BUSINESS
      # ============================================================

      def get_business
        customer =
          ::User.find(params[:id])

        business =
          ::Business.find(
            params[:business_id]
          )

        services =
          ::Service.where(
            business_id: business.id
          )

        business_settings =
          ::BusinessSetting.find_by(
            business_id: business.id
          )

        next_slot =
          BusinessNextAvailableSlot
            .new(business)
            .call

        opening_hours =
          ::BusinessOpeningHour.where(
            business_id: business.id
          )

        if business_settings.latitude.nil? ||
           business_settings.longitude.nil?

          coordinates =
            geocode_business_address(
              business_settings
            )

          if coordinates
            business_settings.update(
              latitude:
                coordinates[:latitude],

              longitude:
                coordinates[:longitude]
            )
          end
        end

        agents_enabled =
          business.feature_enabled?(:agents)

        agent_settings =
          business.agent_settings

        active_agents =
          if agents_enabled
            business
              .business_agents
              .where(status: "active")
              .includes(:user)
          else
            []
          end

        business_data = {
          details: {
            id:
              business.id,

            business_name:
              business_settings.business_name,

            business_category:
              business_settings.business_category,

            phone_number:
              business_settings.phone_number,

            business_email:
              business_settings.business_email,

            business_description:
              business_settings.business_description,

            # ========================================================
            # BUSINESS / SUBSCRIPTION
            # ========================================================

            page_address:
              business.page_address,

            subscription_level:
              business.subscription_level,

            premium:
              %w[
      pro
      pro_plus
    ].include?(
                business.subscription_level.to_s
              ),

            open_today:
              business_open_today?(
                opening_hours
              ),

            logo_url:
              business_logo_url(
                business_settings
              ),

            # ========================================================
            # ADDRESS
            # ========================================================

            address: {
              address_line_1:
                business_settings.address_line_1,

              address_line_2:
                business_settings.address_line_2,

              town_or_city:
                business_settings.town_or_city,

              postcode:
                business_settings.postcode,

              country:
                business_settings.country
            },

            # ========================================================
            # BOOKING SETTINGS
            # ========================================================

            booking_page_live:
              business_settings.booking_page_live,

            automatically_confirm_bookings:
              business_settings
                .automatically_confirm_bookings,

            allow_customer_cancellations:
              business_settings
                .allow_customer_cancellations,

            require_customer_phone_number:
              business_settings
                .require_customer_phone_number,

            cancellation_notice_hours:
              business_settings
                .cancellation_notice_hours,

            new_booking_notifications:
              business_settings
                .new_booking_notifications,

            cancellation_notifications:
              business_settings
                .cancellation_notifications,

            daily_appointment_summary:
              business_settings
                .daily_appointment_summary,

            # ========================================================
            # LOCATION
            # ========================================================

            latitude:
              business_settings.latitude,

            longitude:
              business_settings.longitude,

            created_at:
              business_settings.created_at,

            updated_at:
              business_settings.updated_at
          },

          services:
            services.map do |service|
              {
                id: service.id,
                name: service.name,
                description: service.description,
                price: service.price,
                minutes_duration:
                  service.minutes_duration,
                status: service.status,
                deposit_enabled:
                  service.deposit_enabled,
                deposit: service.deposit,
                icon: service.icon,
                created_at: service.created_at,
                updated_at: service.updated_at
              }
            end,

          opening_hours:
            opening_hours.map do |opening_hour|
              {
                id: opening_hour.id,

                day_of_week:
                  opening_hour.day_of_week,

                open:
                  opening_hour.open,

                opens_at:
                  opening_hour.opens_at,

                closes_at:
                  opening_hour.closes_at,

                created_at:
                  opening_hour.created_at,

                updated_at:
                  opening_hour.updated_at
              }
            end,

          next_slot:
            next_slot ? {
              date: next_slot[:date],
              time: next_slot[:time],

              service: {
                id:
                  next_slot[:service].id,

                name:
                  next_slot[:service].name,

                description:
                  next_slot[:service].description,

                price:
                  next_slot[:service].price,

                minutes_duration:
                  next_slot[:service]
                    .minutes_duration,

                status:
                  next_slot[:service].status,

                deposit_enabled:
                  next_slot[:service]
                    .deposit_enabled,

                deposit:
                  next_slot[:service].deposit,

                icon:
                  next_slot[:service].icon,

                created_at:
                  next_slot[:service].created_at,

                updated_at:
                  next_slot[:service].updated_at
              }
            } : nil,
          agents: {
            enabled:
              agents_enabled,

            allow_any_agent:
              agents_enabled &&
                agent_settings&.agent_selection?,

            agents:
              active_agents.map do |agent|
                {
                  id:
                    agent.id,

                  user_id:
                    agent.user_id,

                  name:
                    [
                      agent.user.first_name,
                      agent.user.last_name
                    ]
                      .compact
                      .join(" "),

                  first_name:
                    agent.user.first_name,

                  last_name:
                    agent.user.last_name
                }
              end
          }
        }

        if params[:distance_to_customer] == "true"
          business_data[:distance_to_customer] =
            business.distance_to_customer(
              customer
            )
        end

        render json: {
          business: business_data
        }, status: :ok
      end


      # ============================================================
      # CREATE CUSTOMER BOOKING
      # ============================================================

      def create_customer_booking
        customer = current_user

        unless customer
          return render json: {
            success: false,
            error:
              "You must be signed in to create a booking."
          }, status: :unauthorized
        end

        unless customer.id == params[:id].to_i
          return render json: {
            success: false,
            error:
              "You are not authorised to create this booking."
          }, status: :forbidden
        end

        business =
          ::Business.find(
            params[:business_id]
          )

        service =
          business.services.find(
            customer_booking_params[:service_id]
          )

        agent =
          nil

        if business.feature_enabled?(:agents)
          agent_selection =
            customer_booking_params[
              :agent_selection
            ]

          # --------------------------------------------------------
          # No agent supplied
          # --------------------------------------------------------

          if agent_selection.blank?
            return render json: {
              success: false,
              error:
                "Please select an agent."
            }, status: :unprocessable_entity
          end

          # --------------------------------------------------------
          # Any agent
          # --------------------------------------------------------

          if agent_selection == "any"
            unless business
                     .agent_settings
                     &.agent_selection?

              return render json: {
                success: false,
                error:
                  "Any agent selection is not available for this business."
              }, status: :unprocessable_entity
            end

            available_agents =
              available_agents_for(
                business:
                  business,

                service:
                  service,

                date:
                  customer_booking_params[
                    :date
                  ],

                time:
                  customer_booking_params[
                    :time
                  ]
              )

            agent =
              available_agents.sample

            unless agent
              return render json: {
                success: false,
                error:
                  "That time is no longer available. Please choose another time."
              }, status: :unprocessable_entity
            end

            # --------------------------------------------------------
            # SPECIFIC AGENT
            # --------------------------------------------------------

          else
            agent =
              business
                .business_agents
                .where(
                  status:
                    "active"
                )
                .find_by(
                  id:
                    agent_selection
                )

            unless agent
              return render json: {
                success: false,
                error:
                  "The selected agent could not be found."
              }, status: :not_found
            end
          end
        end

        # ==========================================================
        # PAYMENT REQUIRED
        #
        # DO NOT create a Booking here.
        #
        # Create a temporary BookingHold instead.
        # The real booking is only created after Stripe confirms
        # successful payment.
        # ==========================================================

        if business.stripe_ready? &&
           payment_required_for?(service)

          booking_hold =
            ::BookingHold.create!(
              user: customer,
              business: business,
              service: service,

              agent_id:
                agent&.user_id,

              date:
                customer_booking_params[:date],

              time:
                customer_booking_params[:time],

              notes:
                customer_booking_params[:notes],

              expires_at:
                30.minutes.from_now
            )

          checkout_session =
            create_customer_stripe_checkout(
              booking_hold: booking_hold,
              business: business,
              service: service
            )

          booking_hold.update!(
            stripe_checkout_session_id:
              checkout_session.id
          )

          return render json: {
            success: true,
            requires_payment: true,

            booking_hold: {
              id: booking_hold.id,

              business_id:
                booking_hold.business_id,

              service_id:
                booking_hold.service_id,

              agent_id:
                booking_hold.agent_id,

              date:
                booking_hold.date,

              time:
                booking_hold.time,

              expires_at:
                booking_hold.expires_at
            },

            payment: {
              checkout_url:
                checkout_session.url,

              checkout_session_id:
                checkout_session.id
            }
          }, status: :created
        end

        # ==========================================================
        # NO PAYMENT REQUIRED
        #
        # Create the actual Booking immediately.
        # ==========================================================

        booking =
          ::Booking.new(
            user: customer,
            business: business,
            service: service,

            agent_id:
              agent&.user_id,

            date:
              customer_booking_params[:date],

            time:
              customer_booking_params[:time],

            notes:
              customer_booking_params[:notes],

            payment_status:
              "not_required",

            amount_paid:
              0
          )

        booking.status =
          if business
               .business_setting
               .automatically_confirm_bookings?
            "confirmed"
          else
            "pending"
          end

        unless booking.save
          return render json: {
            success: false,
            errors:
              booking.errors.full_messages
          }, status: :unprocessable_entity
        end

        # Booking has saved successfully.
        # Now send confirmation notifications.

        send_booking_confirmations(
          booking
        )

        render json: {
          success: true,
          requires_payment: false,

          booking:
            booking_json(
              booking
            )
        }, status: :created

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error:
            "Business or service not found."
        }, status: :not_found

      rescue ActiveRecord::RecordInvalid => e
        render json: {
          success: false,
          errors:
            e.record.errors.full_messages
        }, status: :unprocessable_entity

      rescue Stripe::StripeError => e
        Rails.logger.error(
          "Customer Stripe Checkout error: " \
            "#{e.class} - #{e.message}"
        )

        # If Stripe failed to initialise,
        # remove the temporary hold.
        booking_hold&.destroy

        render json: {
          success: false,
          error:
            "Payment could not be started. Please try again."
        }, status: :unprocessable_entity
      end


      # ============================================================
      # CUSTOMER PAYMENT SUCCESS
      # ============================================================

      def customer_payment_success
        customer = current_user

        unless customer
          return render json: {
            success: false,
            error:
              "You must be signed in."
          }, status: :unauthorized
        end

        unless customer.id == params[:id].to_i
          return render json: {
            success: false,
            error:
              "You are not authorised to access this booking."
          }, status: :forbidden
        end

        booking_hold =
          ::BookingHold.find(
            params[:booking_hold_id]
          )

        unless booking_hold.user_id ==
               customer.id

          return render json: {
            success: false,
            error:
              "You are not authorised to access this booking."
          }, status: :forbidden
        end

        # ----------------------------------------------------------
        # Already completed
        #
        # This makes the endpoint idempotent.
        # If Expo hits it twice we return the same booking.
        # ----------------------------------------------------------

        if booking_hold.booking.present?
          booking =
            booking_hold.booking

          return render json: {
            success: true,
            paid: true,
            already_completed: true,

            booking:
              booking_json(
                booking
              )
          }, status: :ok
        end

        session_id =
          params[:session_id].to_s

        if session_id.blank?
          return render json: {
            success: false,
            error:
              "Stripe session ID is missing."
          }, status: :unprocessable_entity
        end

        stored_session_id =
          booking_hold
            .stripe_checkout_session_id
            .to_s

        if stored_session_id.blank?
          return render json: {
            success: false,
            error:
              "This booking hold does not have a Stripe session."
          }, status: :unprocessable_entity
        end

        unless ActiveSupport::SecurityUtils.secure_compare(
          session_id,
          stored_session_id
        )
          return render json: {
            success: false,
            error:
              "Stripe session does not match the booking hold."
          }, status: :unprocessable_entity
        end

        checkout_session =
          retrieve_customer_checkout_session(
            booking_hold,
            session_id
          )

        Rails.logger.info(
          "Stripe payment verification for booking hold " \
            "#{booking_hold.id}: " \
            "session=#{checkout_session.id}, " \
            "payment_status=#{checkout_session.payment_status}, " \
            "payment_intent=#{checkout_session.payment_intent}"
        )

        unless checkout_session.payment_status ==
               "paid"

          return render json: {
            success: false,
            paid: false,
            error:
              "Payment has not been completed."
          }, status: :unprocessable_entity
        end

        stripe_booking_hold_id =
          checkout_session
            .metadata
            .booking_hold_id
            .to_s

        unless stripe_booking_hold_id ==
               booking_hold.id.to_s

          return render json: {
            success: false,
            error:
              "Stripe payment does not match this booking hold."
          }, status: :unprocessable_entity
        end

        booking =
          complete_customer_paid_booking!(
            booking_hold: booking_hold,
            checkout_session: checkout_session
          )

        render json: {
          success: true,
          paid: true,

          booking:
            booking_json(
              booking
            )
        }, status: :created

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error:
            "Booking hold not found."
        }, status: :not_found

      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error(
          "Customer paid booking creation failed: " \
            "#{e.class} - #{e.message}"
        )

        Rails.logger.error(
          e.record.errors.full_messages.join(", ")
        )

        render json: {
          success: false,
          error:
            "Payment was confirmed by Stripe, but the booking could not be created.",
          errors:
            e.record.errors.full_messages
        }, status: :unprocessable_entity

      rescue Stripe::StripeError => e
        Rails.logger.error(
          "Customer payment verification error: " \
            "#{e.class} - #{e.message}"
        )

        render json: {
          success: false,
          error:
            "We could not verify your payment."
        }, status: :unprocessable_entity

      rescue StandardError => e
        Rails.logger.error(
          "Customer payment success unexpected error: " \
            "#{e.class} - #{e.message}"
        )

        Rails.logger.error(
          e.backtrace.first(20).join("\n")
        )

        render json: {
          success: false,
          error:
            "Payment verification failed.",
          debug_error:
            "#{e.class}: #{e.message}"
        }, status: :internal_server_error
      end


      # ============================================================
      # CUSTOMER PAYMENT CANCELLED
      # ============================================================

      def customer_payment_cancelled
        customer = current_user

        unless customer
          return render json: {
            success: false,
            error:
              "You must be signed in."
          }, status: :unauthorized
        end

        booking_hold =
          ::BookingHold.find(
            params[:booking_hold_id]
          )

        unless booking_hold.user_id ==
               customer.id

          return render json: {
            success: false,
            error:
              "You are not authorised to access this booking."
          }, status: :forbidden
        end

        # There is deliberately NO Booking created here.
        #
        # The BookingHold remains until it expires so that
        # availability can temporarily reserve the slot.

        render json: {
          success: true,
          paid: false,
          cancelled: true,

          booking_created: false,

          booking_hold: {
            id:
              booking_hold.id,

            business_id:
              booking_hold.business_id,

            service_id:
              booking_hold.service_id,

            date:
              booking_hold.date,

            time:
              booking_hold.time,

            expires_at:
              booking_hold.expires_at
          }
        }, status: :ok

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error:
            "Booking hold not found."
        }, status: :not_found
      end


      private


      # ============================================================
      # GEOCODING
      # ============================================================

      def geocode_business_address(
        business_settings
      )
        address = [
          business_settings.address_line_1,
          business_settings.address_line_2,
          business_settings.town_or_city,
          business_settings.postcode,
          business_settings.country
        ].compact.join(", ")

        response =
          HTTParty.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            query: {
              address: address,

              key:
                ENV["GOOGLE_MAPS_API_KEY"].presence ||
                  Rails.application.credentials.dig(
                    :google_maps,
                    :api_key
                  )
            }
          )

        result =
          response
            .parsed_response["results"]
            .first

        return nil unless result

        {
          latitude:
            result["geometry"]["location"]["lat"],

          longitude:
            result["geometry"]["location"]["lng"]
        }
      end


      # ============================================================
      # AVAILABLE AGENTS FOR SLOT
      # ============================================================

      def available_agents_for(
        business:,
        service:,
        date:,
        time:
      )
        date =
          Date.parse(
            date.to_s
          )

        slot_start =
          Time.zone.parse(
            "#{date} #{time}"
          )

        slot_end =
          slot_start +
          service.minutes_duration.minutes

        buffer_minutes =
          business
            .booking_setting
            .buffer_minutes
            .to_i

        business
          .business_agents
          .where(
            status:
              "active"
          )
          .select do |agent|

          booking_conflict =
            business
              .bookings
              .where(
                agent_id:
                  agent.user_id,

                date:
                  date
              )
              .where.not(
              status: [
                "cancelled",
                "no_show"
              ]
            )
              .includes(
                :service
              )
              .any? do |booking|

              booking_start =
                Time.zone.local(
                  date.year,
                  date.month,
                  date.day,
                  booking.time.hour,
                  booking.time.min
                )

              booking_end =
                booking_start +
                booking
                  .service
                  .minutes_duration
                  .minutes +
                buffer_minutes.minutes

              slot_start <
                booking_end &&
                slot_end >
                  booking_start
            end

          hold_conflict =
            business
              .booking_holds
              .active
              .where(
                agent_id:
                  agent.user_id,

                date:
                  date
              )
              .includes(
                :service
              )
              .any? do |hold|

              hold_start =
                Time.zone.local(
                  date.year,
                  date.month,
                  date.day,
                  hold.time.hour,
                  hold.time.min
                )

              hold_end =
                hold_start +
                hold
                  .service
                  .minutes_duration
                  .minutes +
                buffer_minutes.minutes

              slot_start <
                hold_end &&
                slot_end >
                  hold_start
            end

          !booking_conflict &&
            !hold_conflict
        end
      end


      # ============================================================
      # CUSTOMER BOOKING PARAMS
      # ============================================================

      def customer_booking_params
        params
          .require(:booking)
          .permit(
            :service_id,
            :agent_selection,
            :date,
            :time,
            :notes
          )
      end


      # ============================================================
      # DOES SERVICE REQUIRE PAYMENT?
      # ============================================================

      def payment_required_for?(service)
        amount_due =
          if service.deposit_enabled? &&
             service.deposit.present?

            service.deposit.to_d
          else
            service.price.to_d
          end

        amount_due.positive?
      end


      # ============================================================
      # CREATE CUSTOMER STRIPE CHECKOUT
      # ============================================================

      def create_customer_stripe_checkout(
        booking_hold:,
        business:,
        service:
      )
        if service.deposit_enabled? &&
           service.deposit.present? &&
           service.deposit.to_d.positive?

          price =
            service.deposit

          service_name =
            "#{service.name} (Deposit)"
        else
          price =
            service.price

          service_name =
            service.name
        end

        # ----------------------------------------------------------
        # These return directly into the Expo app.
        # Expo receives booking_hold_id instead of booking_id.
        # ----------------------------------------------------------

        success_url =
          "bookpilot://payment-return" \
            "?booking_hold_id=#{booking_hold.id}" \
            "&status=success" \
            "&session_id={CHECKOUT_SESSION_ID}"

        cancel_url =
          "bookpilot://payment-return" \
            "?booking_hold_id=#{booking_hold.id}" \
            "&status=cancelled"

        checkout_session =
          Stripe::Checkout::Session.create(
            {
              mode:
                "payment",

              customer_email:
                booking_hold.user.email,

              line_items: [
                {
                  price_data: {
                    currency:
                      "gbp",

                    product_data: {
                      name:
                        service_name,

                      description:
                        customer_booking_hold_description(
                          booking_hold
                        )
                    },

                    unit_amount:
                      customer_price_in_pence(
                        price
                      )
                  },

                  quantity:
                    1
                }
              ],

              metadata: {
                booking_hold_id:
                  booking_hold.id.to_s,

                business_id:
                  business.id.to_s,

                service_id:
                  service.id.to_s,

                customer_id:
                  booking_hold.user_id.to_s
              },

              payment_intent_data: {
                metadata: {
                  booking_hold_id:
                    booking_hold.id.to_s,

                  business_id:
                    business.id.to_s,

                  customer_id:
                    booking_hold.user_id.to_s
                }
              },

              success_url:
                success_url,

              cancel_url:
                cancel_url,

              expires_at:
                booking_hold.expires_at.to_i
            },
            {
              stripe_account:
                business.stripe_account_id,

              idempotency_key:
                "customer-booking-hold-" \
                  "#{booking_hold.id}-checkout"
            }
          )

        checkout_session
      end


      # ============================================================
      # RETRIEVE STRIPE CHECKOUT SESSION
      # ============================================================

      def retrieve_customer_checkout_session(
        booking_hold,
        session_id
      )
        Stripe::Checkout::Session.retrieve(
          session_id,
          {
            stripe_account:
              booking_hold
                .business
                .stripe_account_id
          }
        )
      end


      # ============================================================
      # COMPLETE PAID BOOKING
      # ============================================================

      def complete_customer_paid_booking!(
        booking_hold:,
        checkout_session:
      )
        CustomerPaidBookingCompletion.new(
          booking_hold: booking_hold,
          checkout_session: checkout_session,
          stripe_account_id: booking_hold.business.stripe_account_id
        ).call
      end


      # ============================================================
      # SEND BOOKING CONFIRMATIONS
      # ============================================================

      def send_booking_confirmations(
        booking
      )
        customer =
          booking.user

        business =
          booking.business

        customer_settings =
          customer.customer_setting

        business_settings =
          business.business_setting

        # ----------------------------------------------------------
        # CUSTOMER
        # ----------------------------------------------------------

        if customer_settings&.booking_confirmations
          begin
            SendBookingConfirmationSmsJob
              .perform_later(
                booking.id
              )
          rescue StandardError => e
            Rails.logger.error(
              "Failed to enqueue customer booking " \
                "confirmation SMS for booking #{booking.id}: " \
                "#{e.class} - #{e.message}"
            )
          end

          begin
            BookingMailer
              .with(
                booking: booking
              )
              .customer_booking_confirmation
              .deliver_later
          rescue StandardError => e
            Rails.logger.error(
              "Failed to enqueue customer booking " \
                "confirmation email for booking #{booking.id}: " \
                "#{e.class} - #{e.message}"
            )
          end
        end

        # ----------------------------------------------------------
        # BUSINESS
        # ----------------------------------------------------------

        if business_settings&.new_booking_notifications
          begin
            SendBusinessBookingConfirmationSmsJob
              .perform_later(
                booking.id
              )
          rescue StandardError => e
            Rails.logger.error(
              "Failed to enqueue business booking " \
                "confirmation SMS for booking #{booking.id}: " \
                "#{e.class} - #{e.message}"
            )
          end

          begin
            BookingMailer
              .with(
                booking: booking
              )
              .business_booking_notification
              .deliver_later
          rescue StandardError => e
            Rails.logger.error(
              "Failed to enqueue business booking " \
                "notification email for booking #{booking.id}: " \
                "#{e.class} - #{e.message}"
            )
          end
        end
      end


      # ============================================================
      # BOOKING JSON
      # ============================================================

      def booking_json(
        booking
      )
        {
          id:
            booking.id,

          business_id:
            booking.business_id,

          service_id:
            booking.service_id,

          agent_id:
            booking.agent_id,

          agent_name:
            if booking.agent
              [
                booking.agent.first_name,
                booking.agent.last_name
              ]
                .compact
                .join(" ")
            end,

          date:
            booking.date,

          time:
            booking.time,

          status:
            booking.status,

          payment_status:
            booking.payment_status,

          amount_paid:
            booking.amount_paid
        }
      end


      # ============================================================
      # PRICE TO PENCE
      # ============================================================

      def customer_price_in_pence(
        price
      )
        (
          BigDecimal(
            price.to_s
          ) * 100
        ).round.to_i
      end


      # ============================================================
      # BOOKING HOLD DESCRIPTION
      # ============================================================

      def customer_booking_hold_description(
        booking_hold
      )
        date =
          booking_hold
            .date
            .strftime(
              "%d %B %Y"
            )

        time =
          booking_hold
            .time
            .strftime(
              "%I:%M %p"
            )

        "#{date} at #{time}"
      end


      # ============================================================
      # STRIPE AMOUNT TO DECIMAL
      # ============================================================

      def amount_from_stripe(
        amount_in_pence
      )
        BigDecimal(
          amount_in_pence.to_s
        ) / 100
      end

      # ============================================================
      # DISTANCE FILTER
      # ============================================================

      def distance_limit_from_param(
        value
      )
        return nil if value.blank?

        numeric =
          value.to_f

        slider_values = {
          0 => 5,
          1 => 10,
          2 => 25,
          3 => 50,
          4 => 100,
          5 => nil
        }

        integer_value =
          value.to_i

        # Web distance slider index
        if value.to_s ==
           integer_value.to_s &&
           slider_values.key?(
             integer_value
           )

          return slider_values[
            integer_value
          ]
        end

        # Allows Expo to send an actual
        # maximum mileage if we want.
        return nil if numeric <= 0

        numeric
      end


      # ============================================================
      # OPEN TODAY
      # ============================================================

      def business_open_today?(
        opening_hours
      )
        today =
          Date.current
              .strftime("%A")
              .downcase

        opening_hour =
          opening_hours.find do |hours|
            hours
              .day_of_week
              .to_s
              .downcase ==
              today
          end

        opening_hour.present? &&
          opening_hour.open?
      end


      # ============================================================
      # BUSINESS LOGO
      # ============================================================

      def business_logo_url(
        business_settings
      )
        return nil unless
          business_settings
            .logo
            .attached?

        rails_blob_url(
          business_settings.logo,
          host:
            request.host_with_port,
          protocol:
            request.protocol
        )
      rescue StandardError => e
        Rails.logger.warn(
          "Unable to generate business logo URL: " \
            "#{e.class} - #{e.message}"
        )

        nil
      end


      # ============================================================
      # NEXT SLOT SORT VALUE
      # ============================================================

      def next_slot_sort_value(
        slot
      )
        date =
          slot[:date].to_date

        time =
          slot[:time]

        time_string =
          if time.respond_to?(
            :strftime
          )
            time.strftime(
              "%H:%M:%S"
            )
          else
            time.to_s
          end

        Time.zone.parse(
          "#{date} #{time_string}"
        ).to_i
      rescue StandardError
        Float::INFINITY
      end


    end
  end
end
