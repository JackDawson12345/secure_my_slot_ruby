module Api
  module V1
    module Business
      class BookingsController < ApplicationController

        skip_before_action :verify_authenticity_token
        before_action :authenticate_api_key!

        def get_bookings
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          bookings = business.bookings

          # Filter by status if provided
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
              {
                id: booking.id,
                business_id: booking.business_id,
                user_id: booking.user_id,
                user_name: booking.user.first_name + ' ' + booking.user.last_name,
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

        def get_booking
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          booking = business.bookings.find_by(id: params[:booking_id])

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          if booking.service.service_category.present?
            category = booking.service.service_category.name
          else
            category = 'Unassigned'
          end

          email_templates = business.email_templates.where(custom: true)
          agreements = business.agreements
          uploaded_images = booking.images

          render json: {
            booking: {
              id: booking.id,
              business_id: booking.business_id,
              user_id: booking.user_id,
              user_name: "#{booking.user.first_name} #{booking.user.last_name}",
              date: booking.date,
              time: booking.time,
              status: booking.status,
              payment_status: booking.payment_status,
              stripe_checkout_session_id: booking.stripe_checkout_session_id,
              stripe_payment_intent_id: booking.stripe_payment_intent_id,
              notes: booking.notes,
              reminder_email_sent_at: booking.reminder_email_sent_at,
              reminder_sms_sent_at: booking.reminder_sms_sent_at,
              total_price: booking.amount,
              amount_paid: booking.amount_paid,
              created_at: booking.created_at,
              updated_at: booking.updated_at,

              users_email: booking.user.email,
              users_phone: booking.user.phone_number,

              service: {
                name: booking.service.name,
                description: booking.service.description,
                price: booking.service.price,
                minutes_duration: booking.service.minutes_duration,
                status: booking.service.status,
                deposit_enabled: booking.service.deposit,
                category: category
              },

              agent: booking.agent ? {
                id: booking.agent.id,
                name: "#{booking.agent.first_name} #{booking.agent.last_name}",
                email: booking.agent.email,
                phone_number: booking.agent.phone_number
              } : nil,

              features: {
                custom_email_templates: business.feature_enabled?(:custom_email_templates),
                agreements: business.feature_enabled?(:agreements),
                client_photos: business.feature_enabled?(:client_photos)
              },

              email_templates: email_templates.map do |template|
                email_status = CustomEmailTemplateStatus.find_by(
                  booking: booking,
                  email_template: template
                )

                if email_status&.status == "sent"
                  status = "Sent"
                else
                  status = "Not Sent"
                end
                {
                  id: template.id,
                  template_type: template.template_type,
                  subject: template.subject,
                  body: template.body,
                  custom: template.custom,
                  created_at: template.created_at,
                  updated_at: template.updated_at,
                  status: status
                }
              end,

              agreements: agreements.map do |agreement|
                agreement_status = AgreementStatus.find_by(
                  booking: booking,
                  agreement: agreement
                )

                {
                  id: agreement.id,
                  name: agreement.name,
                  content: agreement.content,
                  created_at: agreement.created_at,
                  updated_at: agreement.updated_at,
                  status: agreement_status&.status || "Not Sent"
                }
              end,

              consultation_form: {
                responses: booking.consultation_responses,
                token: booking.consultation_token
              },

              uploaded_images: uploaded_images.map do |image|
                {
                  id: image.id,
                  filename: image.filename.to_s,
                  content_type: image.content_type,
                  byte_size: image.byte_size,
                  url: url_for(image)
                }
              end
            }
          }, status: :ok
        end

        def update_status
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          booking = business.bookings.find_by(id: params[:booking_id])

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          user = booking.user
          status = params[:status]

          unless %w[confirmed cancelled completed].include?(status)
            return render json: {
              error: "Invalid status. Status must be confirmed, cancelled or completed."
            }, status: :unprocessable_entity
          end

          if booking.update(status: status)
            render json: {
              message: "Booking status updated successfully.",
              booking: {
                id: booking.id,
                business_id: booking.business_id,
                user_id: booking.user_id,
                date: booking.date,
                time: booking.time,
                status: booking.status,
                payment_status: booking.payment_status,
                notes: booking.notes,
                created_at: booking.created_at,
                updated_at: booking.updated_at
              }
            }, status: :ok

            if user.customer_setting&.booking_changes == true
              SendBookingStatusChangeSmsJob.perform_later(booking.id)
              BookingMailer
                .with(booking: booking)
                .status_changed
                .deliver_now
            end
          else
            render json: {
              error: booking.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def get_booking_slots
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          service = business.services.find_by(
            id: params[:service_id]
          )

          unless service
            return render json: {
              error: "Service not found."
            }, status: :not_found
          end

          begin
            date = Date.parse(params[:date].to_s)
          rescue Date::Error
            return render json: {
              error: "Invalid date."
            }, status: :unprocessable_entity
          end

          agent_selection = params[:agent_selection]

          agent =
            if !business.feature_enabled?(:agents)
              nil
            elsif agent_selection.blank? ||
                  agent_selection == "null"
              nil
            elsif agent_selection == "any"
              "any"
            else
              business.business_agents
                      .where(status: "active")
                      .find_by(id: agent_selection)
            end

          if business.feature_enabled?(:agents) &&
             agent_selection.present? &&
             agent_selection != "null" &&
             agent_selection != "any" &&
             agent.nil?

            return render json: {
              error: "Agent not found."
            }, status: :not_found
          end

          slots = BookingAvailability.new(
            business,
            service,
            date,
            agent
          ).call

          render json: {
            business_id: business.id,
            service_id: service.id,
            agent_selection: agent_selection,
            date: date,
            slots: slots
          }, status: :ok
        end

        def create
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          service = business.services.find_by(
            id: booking_params[:service_id]
          )

          unless service
            return render json: {
              error: "Service not found."
            }, status: :not_found
          end

          # -----------------------------------------
          # Agent
          # -----------------------------------------

          agent = nil

          if business.feature_enabled?(:agents)

            agent_selection =
              booking_params[:agent_selection]

            if agent_selection == "any"

              available_agents = available_agents_for(
                business: business,
                service: service,
                date: booking_params[:date],
                time: booking_params[:time]
              )

              agent = available_agents.sample

              unless agent
                return render json: {
                  success: false,
                  error: "That time is no longer available. Please choose another time."
                }, status: :unprocessable_entity
              end

            elsif agent_selection.present?

              agent = business.business_agents
                              .where(status: "active")
                              .find_by(id: agent_selection)

              unless agent
                return render json: {
                  success: false,
                  error: "The selected agent could not be found."
                }, status: :not_found
              end

            end

          end

          # -----------------------------------------
          # Customer
          # -----------------------------------------

          email =
            booking_params[:email]
              .to_s
              .downcase
              .strip

          user = User.find_or_initialize_by(
            email: email
          )

          new_customer = user.new_record?

          user.first_name =
            booking_params[:first_name]

          user.last_name =
            booking_params[:last_name]

          user.phone_number =
            booking_params[:phone]

          if new_customer
            user.password =
              generate_secure_password

            user.role = :customer
            user.terms_accepted = true
          end

          user.save!

          user.create_customer_setting! unless user.customer_setting

          # -----------------------------------------
          # Business customer
          # -----------------------------------------

          BusinessCustomer.find_or_create_by!(
            business: business,
            user: user
          )

          # -----------------------------------------
          # Booking
          # -----------------------------------------

          booking = Booking.new(
            business_id: business.id,
            user_id: user.id,
            service_id: service.id,
            agent_id: agent&.user_id,
            date: booking_params[:date],
            time: booking_params[:time],
            notes: booking_params[:notes],
            amount: service.price,
            amount_paid: 0,
            payment_status: "not_required"
          )

          booking.status =
            if business
                 .business_setting
                 &.automatically_confirm_bookings?
              "confirmed"
            else
              "pending"
            end

          # -----------------------------------------
          # Save
          # -----------------------------------------

          if booking.save

            # -----------------------------------------
            # New customer welcome email
            # -----------------------------------------

            if new_customer
              CustomerAccountMailer
                .welcome_with_password_setup(user)
                .deliver_later
            end

            # -----------------------------------------
            # Customer booking confirmation
            # -----------------------------------------

            user_settings =
              user.customer_setting ||
              user.create_customer_setting!

            if user_settings.booking_confirmations
              SendBookingConfirmationSmsJob.perform_later(
                booking.id
              )

              BookingMailer
                .with(booking: booking)
                .customer_booking_confirmation
                .deliver_later
            end

            # -----------------------------------------
            # Business booking notification
            # -----------------------------------------

            if business.business_setting&.new_booking_notifications
              SendBusinessBookingConfirmationSmsJob.perform_later(
                booking.id
              )

              BookingMailer
                .with(booking: booking)
                .business_booking_notification
                .deliver_later
            end

            # -----------------------------------------
            # Expo push notifications
            # -----------------------------------------

            begin
              BookingNotificationService.created(
                booking
              )

              Rails.logger.info(
                "PUSH: Notifications queued for manually created booking #{booking.id}"
              )

            rescue StandardError => e
              Rails.logger.error(
                "PUSH: Failed to queue notifications for booking #{booking.id}: " \
                  "#{e.class} - #{e.message}"
              )
            end

            # -----------------------------------------
            # Response
            # -----------------------------------------

            render json: {
              success: true,

              booking: {
                id: booking.id,
                business_id: booking.business_id,
                user_id: booking.user_id,

                user_name:
                  "#{user.first_name} #{user.last_name}",

                service_id: booking.service_id,

                agent_id: booking.agent_id,

                agent_name:
                  if agent
                    "#{agent.user.first_name} #{agent.user.last_name}"
                  end,

                date: booking.date,
                time: booking.time,
                status: booking.status,
                notes: booking.notes,
                amount: booking.amount
              }
            }, status: :created

          else

            render json: {
              success: false,
              errors: booking.errors.full_messages
            }, status: :unprocessable_entity

          end

        rescue ActiveRecord::RecordInvalid => error

          render json: {
            success: false,
            errors: error.record.errors.full_messages
          }, status: :unprocessable_entity

        end

        def send_agreement
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          unless business.feature_enabled?(:agreements)
            return render json: {
              error: "Agreements require a Pro Plus subscription."
            }, status: :forbidden
          end

          booking = business.bookings.find_by(id: params[:booking_id])

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          agreement = business.agreements.find_by(id: params[:agreement_id])

          unless agreement
            return render json: {
              error: "Agreement not found."
            }, status: :not_found
          end

          existing_status = AgreementStatus.find_by(
            booking: booking,
            agreement: agreement
          )

          if existing_status.present?
            return render json: {
              error: "This agreement has already been sent."
            }, status: :unprocessable_entity
          end

          token = SecureRandom.uuid

          AgreementStatus.create!(
            business: business,
            booking: booking,
            agreement: agreement,
            status: "pending",
            token: token
          )

          AgreementMailer
            .sign_agreement(
              agreement,
              booking,
              business
            )
            .deliver_later

          render json: {
            success: true,
            message: "Agreement sent successfully.",
            status: "pending"
          }, status: :ok
        end


        def send_email
          business = ::Business.find_by(id: params[:id])

          unless business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          unless business.feature_enabled?(:custom_email_templates)
            return render json: {
              error: "Custom email templates require a Pro subscription."
            }, status: :forbidden
          end

          booking = business.bookings.find_by(id: params[:booking_id])

          unless booking
            return render json: {
              error: "Booking not found."
            }, status: :not_found
          end

          template = business.email_templates.find_by(id: params[:email_id])

          unless template
            return render json: {
              error: "Email template not found."
            }, status: :not_found
          end

          existing_status = CustomEmailTemplateStatus.find_by(
            booking: booking,
            email_template: template
          )

          if existing_status&.status == "sent"
            return render json: {
              error: "This email has already been sent."
            }, status: :unprocessable_entity
          end

          token = SecureRandom.uuid

          CustomEmailTemplateStatus.create!(
            business: business,
            booking: booking,
            email_template: template,
            status: "sent",
            token: token
          )

          CustomEmailTemplateMailer
            .custom_email_template(template, booking)
            .deliver_later

          render json: {
            success: true,
            message: "Email sent successfully.",
            status: "Sent"
          }, status: :ok
        end

        private

        def available_agents_for(
          business:,
          service:,
          date:,
          time:
        )
          date = Date.parse(date.to_s)

          slot_start = Time.zone.parse(
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
            .where(status: "active")
            .select do |agent|

            booking_conflict =
              business
                .bookings
                .where(
                  agent_id: agent.user_id,
                  date: date
                )
                .where.not(
                status: [
                  "cancelled",
                  "no_show"
                ]
              )
                .includes(:service)
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

                slot_start < booking_end &&
                  slot_end > booking_start
              end

            hold_conflict =
              business
                .booking_holds
                .active
                .where(
                  agent_id: agent.user_id,
                  date: date
                )
                .includes(:service)
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

                slot_start < hold_end &&
                  slot_end > hold_start
              end

            !booking_conflict &&
              !hold_conflict
          end
        end

        def booking_params
          params
            .require(:booking)
            .permit(
              :service_id,
              :agent_selection,
              :date,
              :time,
              :first_name,
              :last_name,
              :email,
              :phone,
              :notes
            )
        end

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

        def generate_secure_password
          uppercase = ('A'..'Z').to_a.sample
          lowercase = ('a'..'z').to_a.sample
          number = ('0'..'9').to_a.sample
          special = %w[! @ # $ % ^ & *].sample

          remaining =
            Array.new(8) do
              (
                ('A'..'Z').to_a +
                  ('a'..'z').to_a +
                  ('0'..'9').to_a +
                  %w[! @ # $ % ^ & *]
              ).sample
            end

          (
            [
              uppercase,
              lowercase,
              number,
              special,
              *remaining
            ]
          ).shuffle.join
        end



      end
    end
  end
end

