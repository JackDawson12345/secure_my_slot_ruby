
# app/controllers/api/v1/agent/bookings_controller.rb

module Api
  module V1
    module Agent
      class BookingsController < Api::V1::BaseController

        before_action :authenticate_api_key!
        before_action :authenticate_agent!
        before_action :set_business_agent!
        before_action :set_booking!,
                      only: [
                        :show,
                        :update_status,
                        :send_agreement,
                        :send_email
                      ]

        # =================================================
        # GET BOOKINGS
        # =================================================

        def index
          today = Date.current

          current_time = Time.current.strftime("%H:%M:%S")

          # -----------------------------------------------
          # Booking visibility
          # -----------------------------------------------

          all_bookings = @business.bookings

          mine_bookings = all_bookings.where(
            agent_id: @agent.id
          )

          booking_view =
            if @can_view_all_bookings &&
               params[:view] == "all"
              "all"
            else
              "mine"
            end

          bookings_scope =
            booking_view == "all" ?
              all_bookings : mine_bookings

          # -----------------------------------------------
          # Statistics
          # These are calculated before search filters,
          # matching the web dashboard.
          # -----------------------------------------------

          today_bookings = bookings_scope.where(
            date: today
          )

          today_count = today_bookings.count

          today_confirmed_count =
            today_bookings.where(
              status: "confirmed"
            ).count

          today_pending_count =
            today_bookings.where(
              status: "pending"
            ).count

          upcoming_count = bookings_scope
                             .where(
                               date: today..(today + 7.days)
                             )
                             .where(
                               "bookings.date > :today OR " \
                                 "(bookings.date = :today AND " \
                                 "bookings.time >= :current_time)",
                               today: today,
                               current_time: current_time
                             )
                             .count

          completed_count = bookings_scope
                              .where(status: "completed")
                              .where(
                                date: today.beginning_of_month..
                                  today.end_of_month
                              )
                              .count

          cancelled_count = bookings_scope
                              .where(status: "cancelled")
                              .where(
                                date: today.beginning_of_month..
                                  today.end_of_month
                              )
                              .count

          my_bookings_count =
            mine_bookings.count

          all_bookings_count =
            @can_view_all_bookings ?
              all_bookings.count :
              my_bookings_count

          # -----------------------------------------------
          # Status filter
          # -----------------------------------------------

          allowed_statuses = %w[
            confirmed
            pending
            completed
            cancelled
          ]

          if allowed_statuses.include?(
            params[:status]
          )
            bookings_scope = bookings_scope.where(
              status: params[:status]
            )
          end

          # -----------------------------------------------
          # Search
          # -----------------------------------------------

          if params[:q].present?
            search = "%#{
              ActiveRecord::Base.sanitize_sql_like(
                params[:q].strip
              )
            }%"

            bookings_scope = bookings_scope
                               .joins(:user, :service)
                               .where(
                                 <<~SQL.squish,
                  users.first_name ILIKE :search
                  OR users.last_name ILIKE :search
                  OR users.email ILIKE :search
                  OR services.name ILIKE :search
                SQL
                                 search: search
                               )
          end

          # -----------------------------------------------
          # Service filter
          # -----------------------------------------------

          if params[:service_id].present?
            bookings_scope = bookings_scope.where(
              service_id: params[:service_id]
            )
          end

          # -----------------------------------------------
          # Date filters
          # -----------------------------------------------

          if params[:date_from].present?
            bookings_scope = bookings_scope.where(
              "bookings.date >= ?",
              Date.iso8601(params[:date_from])
            )
          end

          if params[:date_to].present?
            bookings_scope = bookings_scope.where(
              "bookings.date <= ?",
              Date.iso8601(params[:date_to])
            )
          end

          # -----------------------------------------------
          # Pagination
          # -----------------------------------------------

          per_page = params[:per_page].to_i
          per_page = 10 if per_page <= 0
          per_page = [per_page, 50].min

          current_page = params[:page].to_i
          current_page = 1 if current_page < 1

          total_bookings = bookings_scope.count

          total_pages = [
            (total_bookings.to_f / per_page).ceil,
            1
          ].max

          current_page = [
            current_page,
            total_pages
          ].min

          bookings = bookings_scope
                       .includes(:user, :service, :agent)
                       .order(
                         date: :asc,
                         time: :asc,
                         id: :asc
                       )
                       .offset(
                         (current_page - 1) * per_page
                       )
                       .limit(per_page)

          booking_start =
            if total_bookings.zero?
              0
            else
              ((current_page - 1) * per_page) + 1
            end

          booking_end = [
            current_page * per_page,
            total_bookings
          ].min

          # -----------------------------------------------
          # Available services
          # -----------------------------------------------

          services = @business.services
                              .order(:name)
                              .map do |service|
            {
              id: service.id,
              name: service.name
            }
          end

          # -----------------------------------------------
          # JSON response
          # -----------------------------------------------

          render json: {
            message: "Agent bookings loaded.",

            agent: {
              id: @agent.id,
              first_name: @agent.first_name,
              last_name: @agent.last_name
            },

            business: {
              id: @business.id,
              business_name: @business.business_name
            },

            settings: {
              can_view_all_bookings:
                @can_view_all_bookings,
              booking_visibility:
                @booking_visibility,
              booking_view: booking_view
            },

            booking_counts: {
              mine: my_bookings_count,
              all: all_bookings_count
            },

            statistics: {
              today: today_count,
              today_confirmed:
                today_confirmed_count,
              today_pending:
                today_pending_count,
              upcoming: upcoming_count,
              completed: completed_count,
              cancelled: cancelled_count
            },

            filters: {
              view: booking_view,
              status: params[:status],
              q: params[:q],
              service_id: params[:service_id],
              date_from: params[:date_from],
              date_to: params[:date_to]
            },

            services: services,

            bookings: bookings.map do |booking|
              booking_summary_json(booking)
            end,

            pagination: {
              current_page: current_page,
              per_page: per_page,
              total_pages: total_pages,
              total_bookings: total_bookings,
              booking_start: booking_start,
              booking_end: booking_end,
              has_next_page:
                current_page < total_pages,
              has_previous_page:
                current_page > 1
            }
          }, status: :ok

        rescue Date::Error
          render json: {
            error: "Invalid date format. Use YYYY-MM-DD."
          }, status: :unprocessable_entity
        end

        # =================================================
        # GET SINGLE BOOKING
        # =================================================

        def show
          agreement_statuses = AgreementStatus
                                 .where(
                                   business: @business,
                                   booking: @booking
                                 )
                                 .order(created_at: :desc)
                                 .to_a
                                 .index_by(&:agreement_id)

          email_statuses =
            CustomEmailTemplateStatus
              .where(
                business: @business,
                booking: @booking
              )
              .order(created_at: :desc)
              .to_a
              .index_by(&:email_template_id)

          agreements = @business.agreements.map do |agreement|
            agreement_status =
              agreement_statuses[agreement.id]

            {
              id: agreement.id,
              name: agreement.name,
              status: agreement_status&.status ||
                "not_sent",
              status_id: agreement_status&.id,
              signed_at:
                agreement_status&.signed_at,
              token:
                agreement_status&.status == "signed" ?
                  agreement_status.token : nil,

              can_send:
                agreement_status.nil?
            }
          end

          email_templates = @business
                              .email_templates
                              .where(custom: true)
                              .map do |template|
            template_status =
              email_statuses[template.id]

            {
              id: template.id,
              template_type:
                template.template_type,
              subject: template.subject,
              status:
                template_status&.status ||
                  "not_sent",
              can_send: true,
              can_resend:
                template_status&.status == "sent"
            }
          end

          consultation_responses =
            @booking.consultation_responses || []

          images =
            if @booking.images.attached?
              @booking.images.map do |image|
                {
                  id: image.id,
                  filename: image.filename.to_s,
                  content_type: image.content_type,
                  url: rails_blob_url(
                    image,
                    host: request.host,
                    protocol: request.protocol
                  )
                }
              end
            else
              []
            end

          amount = @booking.amount.to_d

          amount_paid = @booking.amount_paid.to_d

          outstanding = amount - amount_paid

          allowed_transitions = {
            "pending" => ["confirmed"],
            "confirmed" => ["completed"],
            "completed" => ["confirmed"]
          }

          render json: {
            message: "Agent booking loaded.",

            business: {
              id: @business.id,
              business_name:
                @business.business_name
            },

            settings: {
              can_view_all_bookings:
                @can_view_all_bookings,
              booking_visibility:
                @booking_visibility
            },

            booking: booking_summary_json(
              @booking
            ).merge(
              notes: @booking.notes,
              created_at: @booking.created_at,

              customer: customer_json(
                @booking.user
              ),

              service: service_json(
                @booking.service
              ),

              payment: {
                amount: amount.to_f,
                amount_paid: amount_paid.to_f,
                outstanding: outstanding.to_f,
                payment_status:
                  @booking.payment_status,
                stripe_payment_link:
                  @booking.stripe_payment_link,
                currency: "GBP"
              },

              consultation_form: {
                responses:
                  consultation_responses
              },

              images: images,

              agreements: agreements,

              email_templates: email_templates,

              allowed_status_transitions:
                allowed_transitions.fetch(
                  @booking.status,
                  []
                )
            )
          }, status: :ok
        end

        # =================================================
        # UPDATE BOOKING STATUS
        # =================================================

        def update_status
          new_status = params[:status].to_s

          allowed_transitions = {
            "pending" => ["confirmed"],
            "confirmed" => ["completed"],
            "completed" => ["confirmed"]
          }

          allowed = allowed_transitions.fetch(
            @booking.status,
            []
          )

          unless allowed.include?(new_status)
            return render json: {
              error: "That booking status change is not allowed.",
              current_status: @booking.status,
              allowed_statuses: allowed
            }, status: :unprocessable_entity
          end

          if @booking.update(status: new_status)

            if @booking.user
                 &.customer_setting
                 &.booking_changes

              BookingMailer
                .with(booking: @booking)
                .status_changed
                .deliver_now

              SendBookingStatusChangeSmsJob
                .perform_later(@booking.id)
            end

            render json: {
              message: case new_status
                       when "confirmed"
                         "Booking marked as confirmed."
                       when "completed"
                         "Booking marked as completed."
                       else
                         "Booking status updated."
                       end,

              booking: booking_summary_json(
                @booking
              )

            }, status: :ok

          else
            render json: {
              error: "Could not update booking status.",
              details: @booking.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # =================================================
        # SEND AGREEMENT
        # =================================================

        def send_agreement
          agreement = @business.agreements.find_by(
            id: params[:agreement_id]
          )

          unless agreement
            return render json: {
              error: "Agreement not found."
            }, status: :not_found
          end

          existing_status = AgreementStatus.find_by(
            business: @business,
            booking: @booking,
            agreement: agreement
          )

          if existing_status
            return render json: {
              error: "Agreement already sent.",
              status: existing_status.status
            }, status: :unprocessable_entity
          end

          token = SecureRandom.uuid

          agreement_status = AgreementStatus.create!(
            business: @business,
            booking: @booking,
            agreement: agreement,
            status: "pending",
            token: token
          )

          AgreementMailer
            .sign_agreement(
              agreement,
              @booking,
              @business
            )
            .deliver_now

          render json: {
            message: "Agreement sent successfully.",

            agreement: {
              id: agreement.id,
              name: agreement.name,
              status: agreement_status.status
            }
          }, status: :ok
        end

        # =================================================
        # SEND CUSTOM EMAIL
        # =================================================

        def send_email
          template = @business.email_templates
                              .where(custom: true)
                              .find_by(id: params[:email_id])

          unless template
            return render json: {
              error: "Email template not found."
            }, status: :not_found
          end

          existing_status =
            CustomEmailTemplateStatus.find_by(
              business: @business,
              booking: @booking,
              email_template: template
            )

          resend = ActiveModel::Type::Boolean
                     .new.cast(params[:resend])

          if existing_status && !resend
            return render json: {
              error: "Email already sent. Use resend to send it again."
            }, status: :unprocessable_entity
          end

          if !existing_status && resend
            return render json: {
              error: "Email has not been sent yet."
            }, status: :unprocessable_entity
          end

          unless existing_status
            CustomEmailTemplateStatus.create!(
              business: @business,
              booking: @booking,
              email_template: template,
              status: "sent",
              token: SecureRandom.uuid
            )
          end

          CustomEmailTemplateMailer
            .custom_email_template(
              template,
              @booking
            )
            .deliver_later

          render json: {
            message: resend ?
                       "Email queued to resend." :
                       "Email queued successfully.",

            email_template: {
              id: template.id,
              subject: template.subject,
              status: "sent"
            }
          }, status: :ok
        end

        private

        # =================================================
        # AUTHENTICATE SIGNED-IN AGENT
        # =================================================

        def authenticate_agent!
          @agent = current_user

          unless @agent &&
                 @agent.role.to_s == "agent"

            render json: {
              error: "Agent authentication required."
            }, status: :unauthorized
          end
        end

        # =================================================
        # FIND AGENT'S BUSINESS
        # =================================================

        def set_business_agent!
          return if performed?

          memberships = ::BusinessAgent.where(
            user_id: @agent.id,
            status: "active"
          )

          if params[:business_id].present?
            memberships = memberships.where(
              business_id: params[:business_id]
            )
          elsif memberships.count > 1
            return render json: {
              error: "Please specify a business_id."
            }, status: :unprocessable_entity
          end

          @business_agent = memberships.first

          unless @business_agent
            return render json: {
              error: "Active business agent relationship not found."
            }, status: :not_found
          end

          @business = ::Business.find_by(
            id: @business_agent.business_id
          )

          unless @business
            return render json: {
              error: "Business not found."
            }, status: :not_found
          end

          settings = ::BusinessAgentSetting.find_by(
            business_id: @business.id
          )

          @booking_visibility =
            settings&.booking_visibility || "mine"

          @can_view_all_bookings =
            @booking_visibility == "all_bookings"
        end

        # =================================================
        # ACCESSIBLE BOOKINGS
        # =================================================

        def accessible_bookings
          scope = @business.bookings

          if @can_view_all_bookings
            scope
          else
            scope.where(
              agent_id: @agent.id
            )
          end
        end

        # =================================================
        # FIND BOOKING
        # =================================================

        def set_booking!
          return if performed?

          @booking = accessible_bookings
                       .includes(:user, :service, :agent)
                       .find_by(id: params[:booking_id])

          unless @booking
            render json: {
              error: "Booking not found or access denied."
            }, status: :not_found
          end
        end

        # =================================================
        # CUSTOMER JSON
        # =================================================

        def customer_json(customer)
          return nil unless customer

          name = [
            customer.first_name,
            customer.last_name
          ].compact.join(" ").strip

          name = customer.email.to_s
                         .split("@")
                         .first
                         .to_s
                         .titleize if name.blank?

          {
            id: customer.id,
            first_name: customer.first_name,
            last_name: customer.last_name,
            name: name,
            email: customer.email,
            phone_number: customer.phone_number
          }
        end

        # =================================================
        # SERVICE JSON
        # =================================================

        def service_json(service)
          return nil unless service

          {
            id: service.id,
            name: service.name,
            minutes_duration:
              service.minutes_duration,
            price: service.price
          }
        end

        # =================================================
        # BOOKING SUMMARY JSON
        # =================================================

        def booking_summary_json(booking)
          {
            id: booking.id,

            date: booking.date,

            time: booking.time&.strftime(
              "%H:%M"
            ),

            formatted_time:
              booking.time&.strftime(
                "%-I:%M %P"
              ),

            status: booking.status,

            amount: booking.amount.to_f,

            customer: customer_json(
              booking.user
            ),

            service: service_json(
              booking.service
            ),

            agent: {
              id: booking.agent_id,
              is_mine:
                booking.agent_id == @agent.id
            },

            is_mine:
              booking.agent_id == @agent.id
          }
        end

        # =================================================
        # API KEY AUTHENTICATION
        # =================================================

        def authenticate_api_key!
          provided_api_key =
            request.headers["X-API-Key"]

          expected_api_key =
            ENV["SECURE_MY_SLOT_API_KEY"].presence ||
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
