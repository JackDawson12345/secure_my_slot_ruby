module Api
  module V1
    class BusinessesController < ApplicationController
      skip_before_action :verify_authenticity_token

      # ============================================================
      # GET BUSINESSES
      # ============================================================

      def get_businesses
        customer = ::User.find(params[:id])

        businesses = ::Business.all

        if params[:category].present?
          businesses =
            businesses
              .joins(:business_setting)
              .where(
                business_settings: {
                  business_category: params[:category]
                }
              )
        end

        businesses_per_page = params[:businesses_per_page].to_i
        page = params[:page].to_i

        businesses_per_page = 10 if businesses_per_page.zero?
        page = 1 if page.zero?

        total_businesses = businesses.count

        total_pages =
          (
            total_businesses.to_f /
              businesses_per_page
          ).ceil

        paginated_businesses =
          businesses
            .order(created_at: :desc)
            .limit(businesses_per_page)
            .offset(
              (page - 1) * businesses_per_page
            )

        render json: {
          total_businesses: total_businesses,
          businesses_per_page: businesses_per_page,
          current_page: page,
          total_pages: total_pages,
          category_filter: params[:category],

          businesses: paginated_businesses.map do |business|
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
                  latitude: coordinates[:latitude],
                  longitude: coordinates[:longitude]
                )
              end
            end

            business_data = {
              details: {
                id: business.id,
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

              services: services.map do |service|
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
                    open: opening_hour.open,
                    opens_at: opening_hour.opens_at,
                    closes_at: opening_hour.closes_at,
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
                } : nil
            }

            if params[:distance_to_customer] == "true"
              business_data[:distance_to_customer] =
                business.distance_to_customer(
                  customer
                )
            end

            business_data
          end
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

        business_data = {
          details: {
            id: business.id,

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
            } : nil
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
      # CUSTOMER BOOKING PARAMS
      # ============================================================

      def customer_booking_params
        params
          .require(:booking)
          .permit(
            :service_id,
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
          "securemyslot://payment-return" \
            "?booking_hold_id=#{booking_hold.id}" \
            "&status=success" \
            "&session_id={CHECKOUT_SESSION_ID}"

        cancel_url =
          "securemyslot://payment-return" \
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
        booking = nil
        booking_created = false

        ::BookingHold.transaction do
          booking_hold.lock!

          # --------------------------------------------------------
          # If another request has already converted this hold,
          # simply return the existing booking.
          # --------------------------------------------------------

          if booking_hold.booking.present?
            booking =
              booking_hold.booking

            next
          end

          unless checkout_session.payment_status ==
                 "paid"

            raise Stripe::StripeError,
                  "Checkout Session has not been paid."
          end

          # --------------------------------------------------------
          # Determine pending / confirmed status
          # --------------------------------------------------------

          status =
            if booking_hold
                 .business
                 .business_setting
                 .automatically_confirm_bookings?

              "confirmed"
            else
              "pending"
            end

          # --------------------------------------------------------
          # Create the REAL booking
          # --------------------------------------------------------

          booking =
            ::Booking.create!(
              user:
                booking_hold.user,

              business:
                booking_hold.business,

              service:
                booking_hold.service,

              date:
                booking_hold.date,

              time:
                booking_hold.time,

              notes:
                booking_hold.notes,

              status:
                status,

              payment_status:
                "paid",

              stripe_checkout_session_id:
                checkout_session.id,

              stripe_payment_intent_id:
                checkout_session.payment_intent,

              amount_paid:
                amount_from_stripe(
                  checkout_session.amount_total
                )
            )

          # --------------------------------------------------------
          # Attach booking to hold
          # --------------------------------------------------------

          booking_hold.update!(
            booking:
              booking,

            completed_at:
              Time.current
          )

          booking_created = true
        end

        # ----------------------------------------------------------
        # IMPORTANT
        #
        # Send confirmations ONLY when a brand-new Booking was
        # successfully created.
        #
        # If this endpoint is called again, notifications do not
        # get sent twice.
        # ----------------------------------------------------------

        if booking_created
          send_booking_confirmations(
            booking
          )
        end

        booking
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
    end
  end
end