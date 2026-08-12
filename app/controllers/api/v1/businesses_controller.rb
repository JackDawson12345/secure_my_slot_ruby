module Api
  module V1
    class BusinessesController < ApplicationController
      skip_before_action :verify_authenticity_token

      def get_businesses

        customer = ::User.find(params[:id])

        businesses = ::Business.all

        if params[:category].present?
          businesses = businesses.joins(:business_setting)
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
        total_pages = (total_businesses.to_f / businesses_per_page).ceil

        paginated_businesses = businesses
                                 .order(created_at: :desc)
                                 .limit(businesses_per_page)
                                 .offset((page - 1) * businesses_per_page)


        render json: {
          total_businesses: total_businesses,
          businesses_per_page: businesses_per_page,
          current_page: page,
          total_pages: total_pages,
          category_filter: params[:category],

          businesses: paginated_businesses.map do |business|

            services = ::Service.where(business_id: business.id)
            businessSettings = ::BusinessSetting.find_by(business_id: business.id)
            next_slot = BusinessNextAvailableSlot.new(business).call
            opening_hours = ::BusinessOpeningHour.where(business_id: business.id)


            if businessSettings.latitude.nil? || businessSettings.longitude.nil?
              coordinates = geocode_business_address(businessSettings)

              if coordinates
                businessSettings.update(
                  latitude: coordinates[:latitude],
                  longitude: coordinates[:longitude]
                )
              end
            end


            business_data = {

              details: {
                id: business.id,
                business_name: businessSettings.business_name,
                business_category: businessSettings.business_category,
                phone_number: businessSettings.phone_number,
                business_email: businessSettings.business_email,
                business_description: businessSettings.business_description,

                address: {
                  address_line_1: businessSettings.address_line_1,
                  address_line_2: businessSettings.address_line_2,
                  town_or_city: businessSettings.town_or_city,
                  postcode: businessSettings.postcode,
                  country: businessSettings.country,
                },

                booking_page_live: businessSettings.booking_page_live,
                automatically_confirm_bookings: businessSettings.automatically_confirm_bookings,
                allow_customer_cancellations: businessSettings.allow_customer_cancellations,
                require_customer_phone_number: businessSettings.require_customer_phone_number,
                cancellation_notice_hours: businessSettings.cancellation_notice_hours,
                new_booking_notifications: businessSettings.new_booking_notifications,
                cancellation_notifications: businessSettings.cancellation_notifications,
                daily_appointment_summary: businessSettings.daily_appointment_summary,
                latitude: businessSettings.latitude,
                longitude: businessSettings.longitude,
                created_at: businessSettings.created_at,
                updated_at: businessSettings.updated_at,
              },


              services: services.map do |service|
                {
                  id: service.id,
                  name: service.name,
                  description: service.description,
                  price: service.price,
                  minutes_duration: service.minutes_duration,
                  status: service.status,
                  deposit_enabled: service.deposit_enabled,
                  deposit: service.deposit,
                  icon: service.icon,
                  created_at: service.created_at,
                  updated_at: service.updated_at,
                }
              end,


              opening_hours: opening_hours.map do |opening_hour|
                {
                  id: opening_hour.id,
                  day_of_week: opening_hour.day_of_week,
                  open: opening_hour.open,
                  opens_at: opening_hour.opens_at,
                  closes_at: opening_hour.closes_at,
                  created_at: opening_hour.created_at,
                  updated_at: opening_hour.updated_at,
                }
              end,


              next_slot: next_slot ? {
                date: next_slot[:date],
                time: next_slot[:time],

                service: {
                  id: next_slot[:service].id,
                  name: next_slot[:service].name,
                  description: next_slot[:service].description,
                  price: next_slot[:service].price,
                  minutes_duration: next_slot[:service].minutes_duration,
                  status: next_slot[:service].status,
                  deposit_enabled: next_slot[:service].deposit_enabled,
                  deposit: next_slot[:service].deposit,
                  icon: next_slot[:service].icon,
                  created_at: next_slot[:service].created_at,
                  updated_at: next_slot[:service].updated_at,
                }

              } : nil
            }


            if params[:distance_to_customer] == 'true'
              business_data[:distance_to_customer] = business.distance_to_customer(customer)
            end


            business_data

          end

        }, status: :ok

      end

      def get_business
        customer = ::User.find(params[:id])

        business = ::Business.find(params[:business_id])

        services = ::Service.where(business_id: business.id)
        businessSettings = ::BusinessSetting.find_by(business_id: business.id)
        next_slot = BusinessNextAvailableSlot.new(business).call
        opening_hours = ::BusinessOpeningHour.where(business_id: business.id)

        if businessSettings.latitude.nil? || businessSettings.longitude.nil?
          coordinates = geocode_business_address(businessSettings)

          if coordinates
            businessSettings.update(
              latitude: coordinates[:latitude],
              longitude: coordinates[:longitude]
            )
          end
        end

        business_data = {
          details: {
            id: business.id,
            business_name: businessSettings.business_name,
            business_category: businessSettings.business_category,
            phone_number: businessSettings.phone_number,
            business_email: businessSettings.business_email,
            business_description: businessSettings.business_description,

            address: {
              address_line_1: businessSettings.address_line_1,
              address_line_2: businessSettings.address_line_2,
              town_or_city: businessSettings.town_or_city,
              postcode: businessSettings.postcode,
              country: businessSettings.country,
            },

            booking_page_live: businessSettings.booking_page_live,
            automatically_confirm_bookings: businessSettings.automatically_confirm_bookings,
            allow_customer_cancellations: businessSettings.allow_customer_cancellations,
            require_customer_phone_number: businessSettings.require_customer_phone_number,
            cancellation_notice_hours: businessSettings.cancellation_notice_hours,
            new_booking_notifications: businessSettings.new_booking_notifications,
            cancellation_notifications: businessSettings.cancellation_notifications,
            daily_appointment_summary: businessSettings.daily_appointment_summary,
            latitude: businessSettings.latitude,
            longitude: businessSettings.longitude,
            created_at: businessSettings.created_at,
            updated_at: businessSettings.updated_at,
          },

          services: services.map do |service|
            {
              id: service.id,
              name: service.name,
              description: service.description,
              price: service.price,
              minutes_duration: service.minutes_duration,
              status: service.status,
              deposit_enabled: service.deposit_enabled,
              deposit: service.deposit,
              icon: service.icon,
              created_at: service.created_at,
              updated_at: service.updated_at,
            }
          end,

          opening_hours: opening_hours.map do |opening_hour|
            {
              id: opening_hour.id,
              day_of_week: opening_hour.day_of_week,
              open: opening_hour.open,
              opens_at: opening_hour.opens_at,
              closes_at: opening_hour.closes_at,
              created_at: opening_hour.created_at,
              updated_at: opening_hour.updated_at,
            }
          end,

          next_slot: next_slot ? {
            date: next_slot[:date],
            time: next_slot[:time],

            service: {
              id: next_slot[:service].id,
              name: next_slot[:service].name,
              description: next_slot[:service].description,
              price: next_slot[:service].price,
              minutes_duration: next_slot[:service].minutes_duration,
              status: next_slot[:service].status,
              deposit_enabled: next_slot[:service].deposit_enabled,
              deposit: next_slot[:service].deposit,
              icon: next_slot[:service].icon,
              created_at: next_slot[:service].created_at,
              updated_at: next_slot[:service].updated_at,
            }
          } : nil
        }

        if params[:distance_to_customer] == 'true'
          business_data[:distance_to_customer] = business.distance_to_customer(customer)
        end

        render json: {
          business: business_data
        }, status: :ok
      end

      def create_customer_booking
        customer = current_user

        unless customer
          render json: {
            success: false,
            error: "You must be signed in to create a booking."
          }, status: :unauthorized

          return
        end

        unless customer.id == params[:id].to_i
          render json: {
            success: false,
            error: "You are not authorised to create this booking."
          }, status: :forbidden

          return
        end

        business = ::Business.find(params[:business_id])

        service = business.services.find(
          customer_booking_params[:service_id]
        )

        booking = ::Booking.new(
          user: customer,
          business: business,
          service: service,
          date: customer_booking_params[:date],
          time: customer_booking_params[:time],
          notes: customer_booking_params[:notes],
          status: "pending",
          payment_status: business.stripe_ready? ? "awaiting_payment" : "not_required"
        )

        unless booking.save
          render json: {
            success: false,
            errors: booking.errors.full_messages
          }, status: :unprocessable_entity

          return
        end

        if business.stripe_ready?
          checkout_session =
            create_customer_stripe_checkout(
              booking: booking,
              business: business,
              service: service
            )

          render json: {
            success: true,
            requires_payment: true,

            booking: {
              id: booking.id,
              business_id: booking.business_id,
              service_id: booking.service_id,
              date: booking.date,
              time: booking.time,
              status: booking.status,
              payment_status: booking.payment_status
            },

            payment: {
              checkout_url: checkout_session.url,
              checkout_session_id: checkout_session.id
            }
          }, status: :created
        else
          SendBookingConfirmationSmsJob.perform_later(
            booking.id
          )

          SendBusinessBookingConfirmationSmsJob.perform_later(
            booking.id
          )

          render json: {
            success: true,
            requires_payment: false,

            booking: {
              id: booking.id,
              business_id: booking.business_id,
              service_id: booking.service_id,
              date: booking.date,
              time: booking.time,
              status: booking.status,
              payment_status: booking.payment_status
            }
          }, status: :created
        end

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "Business or service not found."
        }, status: :not_found

      rescue ActiveRecord::RecordInvalid => e
        render json: {
          success: false,
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity

      rescue Stripe::StripeError => e
        Rails.logger.error(
          "Customer Stripe Checkout error: #{e.class} - #{e.message}"
        )

        booking&.update(
          payment_status: "payment_failed"
        )

        render json: {
          success: false,
          error: "The booking was created, but payment could not be started.",
          booking_id: booking&.id
        }, status: :unprocessable_entity
      end


      def customer_payment_success
        booking = ::Booking.find(
          params[:booking_id]
        )

        unless booking.user_id == current_user&.id
          render json: {
            success: false,
            error: "You are not authorised to access this booking."
          }, status: :forbidden

          return
        end

        session_id =
          params[:session_id].to_s

        if session_id.blank?
          render json: {
            success: false,
            error: "Stripe session ID is missing."
          }, status: :unprocessable_entity

          return
        end

        if booking.stripe_checkout_session_id.blank?
          render json: {
            success: false,
            error: "This booking does not have a Stripe session."
          }, status: :unprocessable_entity

          return
        end

        unless session_id == booking.stripe_checkout_session_id
          render json: {
            success: false,
            error: "Stripe session does not match the booking."
          }, status: :unprocessable_entity

          return
        end

        checkout_session =
          retrieve_customer_checkout_session(
            booking,
            session_id
          )

        unless checkout_session.payment_status == "paid"
          render json: {
            success: false,
            paid: false,
            error: "Payment has not been completed."
          }, status: :unprocessable_entity

          return
        end

        already_paid =
          booking.payment_status == "paid"

        booking.update!(
          stripe_payment_intent_id:
            checkout_session.payment_intent,

          payment_status: "paid",

          amount_paid:
            amount_from_stripe(
              checkout_session.amount_total
            )
        )

        unless already_paid
          SendBookingConfirmationSmsJob.perform_later(
            booking.id
          )

          SendBusinessBookingConfirmationSmsJob.perform_later(
            booking.id
          )
        end

        render json: {
          success: true,
          paid: true,

          booking: {
            id: booking.id,
            status: booking.status,
            payment_status: booking.payment_status,
            amount_paid: booking.amount_paid
          }
        }, status: :ok

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "Booking not found."
        }, status: :not_found

      rescue Stripe::StripeError => e
        Rails.logger.error(
          "Customer payment verification error: #{e.class} - #{e.message}"
        )

        render json: {
          success: false,
          error: "We could not verify your payment."
        }, status: :unprocessable_entity
      end

      def customer_payment_cancelled
        booking =
          ::Booking.find(
            params[:booking_id]
          )

        unless booking.user_id ==
               current_user&.id

          render json: {
            success: false,
            error: "You are not authorised to access this booking."
          }, status: :forbidden

          return
        end

        render json: {
          success: true,
          paid: false,

          booking: {
            id: booking.id,
            status: booking.status,
            payment_status:
              booking.payment_status
          }
        }, status: :ok

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "Booking not found."
        }, status: :not_found
      end


      private


      def geocode_business_address(businessSettings)

        address = [
          businessSettings.address_line_1,
          businessSettings.address_line_2,
          businessSettings.town_or_city,
          businessSettings.postcode,
          businessSettings.country
        ].compact.join(", ")


        response = HTTParty.get(
          "https://maps.googleapis.com/maps/api/geocode/json",
          query: {
            address: address,
            key: "AIzaSyBeTSw6kn3eIqQab4tZy1-EXF9gM91R97U"
          }
        )


        result = response.parsed_response["results"].first

        return nil unless result


        {
          latitude: result["geometry"]["location"]["lat"],
          longitude: result["geometry"]["location"]["lng"]
        }

      end


      def customer_booking_params
        params.require(:booking).permit(
          :service_id,
          :date,
          :time,
          :notes
        )
      end


      def create_customer_stripe_checkout(
        booking:,
        business:,
        service:
      )
        if service.deposit_enabled == true &&
           service.deposit.present? &&
           service.deposit.to_d.positive?

          price = service.deposit
          service_name =
            "#{service.name} (Deposit)"
        else
          price = service.price
          service_name =
            service.name
        end

        success_url =
          "securemyslot://payment-return" \
            "?booking_id=#{booking.id}" \
            "&status=success" \
            "&session_id={CHECKOUT_SESSION_ID}"

        cancel_url =
          "securemyslot://payment-return" \
            "?booking_id=#{booking.id}" \
            "&status=cancelled"
        
        checkout_session =
          Stripe::Checkout::Session.create(
            {
              mode: "payment",

              customer_email:
                booking.user.email,

              line_items: [
                {
                  price_data: {
                    currency: "gbp",

                    product_data: {
                      name: service_name,

                      description:
                        customer_booking_description(
                          booking
                        )
                    },

                    unit_amount:
                      customer_price_in_pence(
                        price
                      )
                  },

                  quantity: 1
                }
              ],

              metadata: {
                booking_id:
                  booking.id.to_s,

                business_id:
                  business.id.to_s,

                service_id:
                  service.id.to_s,

                customer_id:
                  booking.user_id.to_s
              },

              payment_intent_data: {
                metadata: {
                  booking_id:
                    booking.id.to_s,

                  business_id:
                    business.id.to_s,

                  customer_id:
                    booking.user_id.to_s
                }
              },

              success_url:
                success_url,

              cancel_url:
                cancel_url
            },
            {
              stripe_account:
                business.stripe_account_id,

              idempotency_key:
                "customer-booking-#{booking.id}-checkout"
            }
          )

        booking.update!(
          stripe_checkout_session_id:
            checkout_session.id
        )

        checkout_session
      end


      def retrieve_customer_checkout_session(
        booking,
        session_id
      )
        Stripe::Checkout::Session.retrieve(
          session_id,
          {
            stripe_account:
              booking.business.stripe_account_id
          }
        )
      end


      def customer_price_in_pence(price)
        (
          BigDecimal(
            price.to_s
          ) * 100
        ).round.to_i
      end


      def customer_booking_description(
        booking
      )
        date =
          booking.date.strftime(
            "%d %B %Y"
          )

        time =
          booking.time.strftime(
            "%I:%M %p"
          )

        "#{date} at #{time}"
      end


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