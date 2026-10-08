module Api
  module V1
    module Customer
      class BookingsController < ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        def get_booking
          customer = ::User.find_by(
            id: params[:id]
          )

          unless customer
            return render json: {
              error: "Customer not found."
            }, status: :not_found
          end

          booking =
            ::Booking
              .includes(
                :service,
                :business,
                images_attachments: :blob
              )
              .find_by(
                id: params[:booking_id],
                user_id: customer.id
              )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          service = booking.service
          business = booking.business
          settings = business.business_setting

          # =========================================================
          # APPOINTMENT TIME
          # =========================================================

          appointment_time =
            Time.zone.local(
              booking.date.year,
              booking.date.month,
              booking.date.day,
              booking.time.hour,
              booking.time.min
            )

          booking_end_time =
            appointment_time +
            service.minutes_duration.minutes

          # =========================================================
          # CANCELLATION
          # =========================================================

          cancellation_notice_hours =
            settings
              &.cancellation_notice_hours
              .to_i

          cancellation_cutoff =
            appointment_time -
            cancellation_notice_hours.hours

          can_cancel =
            settings
              &.allow_customer_cancellations? &&
            !%w[cancelled completed].include?(
              booking.status
            ) &&
            Time.current <
            cancellation_cutoff &&
            appointment_time >
            Time.current

          cancellation_message =
            if booking.status == "cancelled"
              "This booking has already been cancelled."
            elsif booking.status == "completed"
              "Completed bookings cannot be cancelled."
            elsif appointment_time <= Time.current
              "Past bookings cannot be cancelled."
            elsif !settings&.allow_customer_cancellations?
              "This business does not allow customer cancellations."
            elsif Time.current >= cancellation_cutoff
              "This booking can no longer be cancelled online. Cancellations require at least #{cancellation_notice_hours} hours notice."
            else
              nil
            end

          # =========================================================
          # RESCHEDULING
          # =========================================================

          can_reschedule =
            !%w[cancelled completed].include?(
              booking.status
            ) &&
            appointment_time >
            Time.current

          # =========================================================
          # COUPON
          # =========================================================

          coupon =
            if booking.coupon.present?
              ::ServiceCoupon.find_by(
                business_id:
                  booking.business_id,
                id:
                  booking.coupon
              )
            end

          original_price =
            service.price.to_f

          booking_amount =
            booking.amount.present? ?
              booking.amount.to_f :
              original_price

          coupon_discount =
            coupon.present? ?
              original_price -
                booking_amount :
              0

          # =========================================================
          # CONSULTATION
          # =========================================================

          consultation_responses =
            booking.consultation_responses ||
            []

          consultation_form_url =
            if booking.consultation_token.present? &&
               business.page_address.present?
              "https://#{business.page_address}.book-pilot.co.uk/consultation-form?token=#{booking.consultation_token}"
            end

          # =========================================================
          # RESPONSE
          # =========================================================

          render json: {
            booking: {
              id: booking.id,

              reference:
                "##{booking.id}",

              user_id:
                booking.user_id,

              user_name:
                [
                  booking.user.first_name,
                  booking.user.last_name
                ].compact.join(" "),

              date:
                booking.date,

              time:
                booking.time,

              end_time:
                booking_end_time,

              status:
                booking.status,

              notes:
                booking.notes,

              created_at:
                booking.created_at,

              updated_at:
                booking.updated_at,

              # =====================================================
              # BUSINESS
              # =====================================================

              business: {
                id:
                  business.id,

                name:
                  business.business_name,

                category:
                  settings&.business_category.presence ||
                    business.try(:category),

                page_address:
                  business.page_address,

                phone_number:
                  settings&.phone_number.presence ||
                    business.try(:phone_number),

                email:
                  settings&.business_email,

                address: {
                  address_line_1:
                    settings&.address_line_1,

                  address_line_2:
                    settings&.address_line_2,

                  town_or_city:
                    settings&.town_or_city,

                  postcode:
                    settings&.postcode,

                  country:
                    settings&.country
                }
              },

              # =====================================================
              # SERVICE
              # =====================================================

              service: {
                id:
                  service.id,

                name:
                  service.name,

                description:
                  service.description,

                icon:
                  service.try(:icon),

                price:
                  service.price,

                minutes_duration:
                  service.minutes_duration,

                deposit_enabled:
                  service.try(
                    :deposit_enabled?
                  ),

                deposit:
                  service.try(:deposit)
              },

              # =====================================================
              # PAYMENT
              # =====================================================

              payment: {
                status:
                  booking.payment_status,

                amount:
                  booking_amount,

                amount_paid:
                  booking.amount_paid || 0,

                stripe_checkout_session_id:
                  booking.stripe_checkout_session_id,

                stripe_payment_intent_id:
                  booking.stripe_payment_intent_id
              },

              # =====================================================
              # COUPON
              # =====================================================

              coupon: coupon.present? ? {
                id:
                  coupon.id,

                code:
                  coupon.code,

                discount:
                  coupon_discount
              } : nil,

              # =====================================================
              # CONSULTATION
              # =====================================================

              consultation: {
                submitted:
                  consultation_responses.any?,

                responses:
                  consultation_responses,

                token:
                  booking.consultation_token,

                form_url:
                  consultation_form_url,

                pdf_available:
                  consultation_responses.any?
              },

              # =====================================================
              # IMAGES
              # =====================================================

              images:
                booking.images.map do |image|
                  {
                    id:
                      image.id,

                    filename:
                      image.filename.to_s,

                    content_type:
                      image.content_type,

                    byte_size:
                      image.byte_size,

                    url:
                      rails_blob_url(
                        image,
                        host: request.host,
                        protocol: request.protocol
                      )
                  }
                end,

              image_limit:
                10,

              remaining_image_slots:
                [
                  10 -
                    booking.images.count,
                  0
                ].max,

              # =====================================================
              # CUSTOMER ACTIONS
              # =====================================================

              actions: {
                can_reschedule:
                  can_reschedule,

                can_cancel:
                  can_cancel,

                cancellation_notice_hours:
                  cancellation_notice_hours,

                cancellation_cutoff:
                  cancellation_cutoff,

                cancellation_message:
                  cancellation_message
              },

              reminder_email_sent_at:
                booking.reminder_email_sent_at,

              reminder_sms_sent_at:
                booking.reminder_sms_sent_at
            }
          }, status: :ok
        end

        def upload_images
          customer =
            ::User.find_by(
              id: params[:id]
            )

          unless customer
            return render json: {
              error: "Customer not found."
            }, status: :not_found
          end

          booking =
            ::Booking.find_by(
              id: params[:booking_id],
              user_id: customer.id
            )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          images =
            Array(params[:images])

          if images.empty?
            return render json: {
              error: "Please select at least one image."
            }, status: :unprocessable_entity
          end

          if booking.images.count +
             images.count > 10

            return render json: {
              error:
                "You can upload a maximum of 10 images.",
              current_count:
                booking.images.count,
              remaining_slots:
                [
                  10 -
                    booking.images.count,
                  0
                ].max
            }, status: :unprocessable_entity
          end

          allowed_types = %w[
    image/jpeg
    image/png
    image/webp
  ]

          invalid_images =
            images.reject do |image|
              allowed_types.include?(
                image.content_type
              )
            end

          if invalid_images.any?
            return render json: {
              error:
                "Images must be JPG, PNG or WEBP."
            }, status: :unprocessable_entity
          end

          booking.images.attach(
            images
          )

          render json: {
            message:
              "Images uploaded successfully.",

            images:
              booking.images.reload.map do |image|
                {
                  id:
                    image.id,

                  filename:
                    image.filename.to_s,

                  content_type:
                    image.content_type,

                  byte_size:
                    image.byte_size,

                  url:
                    rails_blob_url(
                      image,
                      host: request.host,
                      protocol: request.protocol
                    )
                }
              end,

            image_count:
              booking.images.count,

            remaining_slots:
              [
                10 -
                  booking.images.count,
                0
              ].max
          }, status: :ok
        end

        def remove_image
          customer =
            ::User.find_by(
              id: params[:id]
            )

          unless customer
            return render json: {
              error: "Customer not found."
            }, status: :not_found
          end

          booking =
            ::Booking.find_by(
              id: params[:booking_id],
              user_id: customer.id
            )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          image =
            booking.images.find_by(
              id: params[:image_id]
            )

          unless image
            return render json: {
              error: "Image not found."
            }, status: :not_found
          end

          image.purge

          render json: {
            message:
              "Image removed successfully.",

            image_count:
              booking.images.count,

            remaining_slots:
              [
                10 -
                  booking.images.count,
                0
              ].max
          }, status: :ok
        end

        def consultation_pdf
          customer =
            ::User.find_by(
              id: params[:id]
            )

          unless customer
            return render json: {
              error: "Customer not found."
            }, status: :not_found
          end

          booking =
            ::Booking.find_by(
              id: params[:booking_id],
              user_id: customer.id
            )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          unless booking
                   .consultation_responses
                   .present?

            return render json: {
              error:
                "No consultation form has been submitted."
            }, status: :unprocessable_entity
          end

          @booking = booking

          render pdf:
                   "consultation-form-#{booking.id}",
                 template:
                   "account/bookings/consultation_pdf",
                 layout:
                   "pdf",
                 disposition:
                   "attachment",
                 page_size:
                   "A4",
                 margin: {
                   top: 15,
                   bottom: 15,
                   left: 15,
                   right: 15
                 }
        end

        def reschedule_slots
          customer =
            ::User.find_by(
              id: params[:id]
            )

          booking =
            ::Booking.find_by(
              id: params[:booking_id],
              user_id: customer&.id
            )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          if %w[
    cancelled
    completed
  ].include?(booking.status)

            return render json: {
              error:
                "This booking cannot be rescheduled."
            }, status: :unprocessable_entity
          end

          date =
            Date.parse(
              params[:date].to_s
            )

          # =========================================================
          # EXISTING ASSIGNED AGENT
          # =========================================================

          business_agent =
            if booking.agent_id.present?
              booking
                .business
                .business_agents
                .find_by(
                  user_id:
                    booking.agent_id
                )
            end

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Booking #{booking.id}"
          )

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Agent user ID #{booking.agent_id.inspect}"
          )

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: BusinessAgent #{business_agent&.id.inspect}"
          )

          slots =
            BookingAvailability.new(
              booking.business,
              booking.service,
              date,
              business_agent
            ).call

          render json: {
            date: date,
            agent: business_agent.present? ? {
              id:
                business_agent.id,

              user_id:
                business_agent.user_id
            } : nil,
            slots: slots
          }, status: :ok

        rescue ArgumentError
          render json: {
            error: "Invalid date.",
            slots: []
          }, status: :unprocessable_entity
        end

        def get_bookings
          customer = ::User.find(params[:id])

          unless customer
            return render json: {
              error: "Customer not found."
            }, status: :not_found
          end

          bookings = ::Booking.where(user_id: customer.id)

          if params[:status].present?
            bookings = bookings.where(status: params[:status])
          end

          bookings_per_page = params[:bookings_per_page].to_i
          page = params[:page].to_i

          bookings_per_page = 10 if bookings_per_page.zero?
          page = 1 if page.zero?

          total_bookings = bookings.count
          total_pages = (total_bookings.to_f / bookings_per_page).ceil

          paginated_bookings = bookings
                                 .order(date: :asc, time: :asc)
                                 .limit(bookings_per_page)
                                 .offset((page - 1) * bookings_per_page)

          render json: {
            total_bookings: total_bookings,
            bookings_per_page: bookings_per_page,
            current_page: page,
            total_pages: total_pages,
            status_filter: params[:status],
            bookings: paginated_bookings.map do |booking|
              business = ::Business.find(booking.business_id)
              businessSettings = ::BusinessSetting.find_by(business_id: business.id)
              service = ::Service.find(booking.service_id)
              {
                id: booking.id,
                business: {
                  id: business.id,
                  name: business.business_name,
                  category: businessSettings.business_category,
                  address: {
                    address_line_1: businessSettings.address_line_1,
                    address_line_2: businessSettings.address_line_2,
                    town_or_city: businessSettings.town_or_city,
                    postcode: businessSettings.postcode,
                    country: businessSettings.country,
                  },
                  phone_number: businessSettings.phone_number
                },
                user_id: booking.user_id,
                user_name: booking.user.first_name + ' ' + booking.user.last_name,
                service: {
                  id: service.id,
                  name: service.name,
                  description: service.description,
                  price: service.price,
                  minutes_duration: service.minutes_duration
                },
                date: booking.date,
                time: booking.time,
                status: booking.status,
                created_at: booking.created_at,
                updated_at: booking.updated_at,
                payment_status: booking.payment_status,
                stripe_checkout_session_id: booking.stripe_checkout_session_id,
                stripe_payment_intent_id: booking.stripe_payment_intent_id,
                notes: booking.notes,
                reminder_email_sent_at: booking.reminder_email_sent_at,
                reminder_sms_sent_at: booking.reminder_sms_sent_at,
                amount_paid: booking.amount_paid
              }
            end
          }, status: :ok
        end

        def reschedule
          customer =
            ::User.find_by(
              id: params[:id]
            )

          booking =
            ::Booking.find_by(
              id: params[:booking_id],
              user_id: customer&.id
            )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          if %w[
    cancelled
    completed
  ].include?(booking.status)

            return render json: {
              error:
                "This booking cannot be rescheduled."
            }, status: :unprocessable_entity
          end

          unless params[:date].present? &&
                 params[:time].present?

            return render json: {
              error:
                "Date and time are required."
            }, status: :unprocessable_entity
          end

          date =
            Date.parse(
              params[:date]
            )

          time =
            params[:time]

          # =========================================================
          # EXISTING ASSIGNED AGENT
          # =========================================================

          business_agent =
            if booking.agent_id.present?
              booking
                .business
                .business_agents
                .find_by(
                  user_id:
                    booking.agent_id
                )
            end

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Validating booking #{booking.id}"
          )

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Date #{date}"
          )

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Time #{time}"
          )

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Agent user ID #{booking.agent_id.inspect}"
          )

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: BusinessAgent #{business_agent&.id.inspect}"
          )

          available_slots =
            BookingAvailability.new(
              booking.business,
              booking.service,
              date,
              business_agent
            ).call

          Rails.logger.info(
            "CUSTOMER RESCHEDULE: Available slots #{available_slots.inspect}"
          )

          unless available_slots.include?(
            time
          )
            return render json: {
              error:
                "That appointment time is no longer available."
            }, status: :unprocessable_entity
          end

          booking.update!(
            date: date,
            time:
              Time.zone.parse(time)
          )

          render json: {
            message:
              "Booking rescheduled successfully.",

            booking: {
              id:
                booking.id,

              date:
                booking.date,

              time:
                booking.time,

              status:
                booking.status,

              agent_id:
                booking.agent_id,

              updated_at:
                booking.updated_at
            }
          }, status: :ok

        rescue ArgumentError
          render json: {
            error:
              "Please select a valid date and time."
          }, status: :unprocessable_entity

        rescue ActiveRecord::RecordInvalid => error
          render json: {
            error:
              "Unable to reschedule booking.",

            errors:
              error.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        def cancel
          customer =
            ::User.find_by(
              id: params[:id]
            )

          booking =
            ::Booking
              .includes(
                business:
                  :business_setting
              )
              .find_by(
                id: params[:booking_id],
                user_id: customer&.id
              )

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          settings =
            booking
              .business
              .business_setting

          unless settings
                   &.allow_customer_cancellations?

            return render json: {
              error:
                "This business does not allow customer cancellations."
            }, status: :unprocessable_entity
          end

          if booking.status ==
             "cancelled"

            return render json: {
              error:
                "This booking has already been cancelled."
            }, status: :unprocessable_entity
          end

          if booking.status ==
             "completed"

            return render json: {
              error:
                "Completed bookings cannot be cancelled."
            }, status: :unprocessable_entity
          end

          appointment_time =
            Time.zone.local(
              booking.date.year,
              booking.date.month,
              booking.date.day,
              booking.time.hour,
              booking.time.min
            )

          if appointment_time <=
             Time.current

            return render json: {
              error:
                "Past bookings cannot be cancelled."
            }, status: :unprocessable_entity
          end

          notice_hours =
            settings
              .cancellation_notice_hours
              .to_i

          cancellation_cutoff =
            appointment_time -
            notice_hours.hours

          if Time.current >=
             cancellation_cutoff

            return render json: {
              error:
                "This booking can no longer be cancelled because it is within the #{notice_hours}-hour cancellation period.",

              cancellation_notice_hours:
                notice_hours,

              cancellation_cutoff:
                cancellation_cutoff
            }, status: :unprocessable_entity
          end

          booking.update!(
            status: "cancelled"
          )

          if settings
               .cancellation_notifications

            BookingMailer
              .with(
                booking: booking
              )
              .booking_cancelled
              .deliver_later
          end

          render json: {
            message:
              "Your booking has been cancelled.",

            booking: {
              id:
                booking.id,

              date:
                booking.date,

              time:
                booking.time,

              status:
                booking.status,

              updated_at:
                booking.updated_at
            }
          }, status: :ok
        end


        private

        def authenticate_api_key!
          provided_api_key = request.headers["X-API-Key"]
          expected_api_key = ENV["SECURE_MY_SLOT_API_KEY"].presence ||
                             Rails.application.credentials.secure_my_slot_api_key

          unless provided_api_key.present? &&
                 expected_api_key.present? &&
                 ActiveSupport::SecurityUtils.secure_compare(
                   provided_api_key,
                   expected_api_key
                 )
            render json: {
              error: "Invalid or missing API key"
            }, status: :unauthorized
          end
        end

      end
    end
  end
end

