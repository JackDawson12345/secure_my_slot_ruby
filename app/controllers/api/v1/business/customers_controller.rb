module Api
  module V1
    module Business
      class CustomersController < ApplicationController

        skip_before_action :verify_authenticity_token

        def get_customers

          business = ::Business.find_by(id: params[:id])

          unless business
            render json: {
              error: "Business not found"
            }, status: :not_found

            return
          end


          bookings = Booking
                       .where(business: business)
                       .where.not(user_id: nil)
                       .includes(:user, :service)
                       .order(date: :desc, time: :desc)


          customers = bookings
                        .group_by(&:user)
                        .map do |user, user_bookings|

            sorted_bookings = user_bookings.sort_by do |booking|
              [
                booking.date,
                booking.time
              ]
            end


            first_booking = sorted_bookings.first
            last_booking = sorted_bookings.last


            {
              user: user,
              bookings: sorted_bookings,
              total_bookings: sorted_bookings.count,
              first_booking: first_booking,
              last_booking: last_booking,

              total_spent: sorted_bookings
                             .select { |booking| booking.status == "confirmed" }
                             .sum do |booking|
                booking.service&.price.to_d
              end,

              active: sorted_bookings.any? do |booking|
                booking.date >= 90.days.ago.to_date
              end
            }

          end


          customers = customers.sort_by do |customer|
            [
              customer[:last_booking].date,
              customer[:last_booking].time
            ]
          end.reverse



          search = params[:search].to_s.strip.downcase


          if search.present?

            customers = customers.select do |customer|

              user = customer[:user]


              full_name =
                "#{user.first_name} #{user.last_name}"
                  .downcase


              email =
                user.email.to_s.downcase


              full_name.include?(search) ||
                email.include?(search)

            end

          end



          customers_per_page = params[:customers_per_page].to_i
          page = params[:page].to_i


          customers_per_page = 10 if customers_per_page.zero?
          page = 1 if page.zero?


          total_customers = customers.count

          total_pages =
            (total_customers.to_f / customers_per_page).ceil


          paginated_customers =
            customers
              .slice(
                (page - 1) * customers_per_page,
                customers_per_page
              ) || []



          render json: {

            total_customers: total_customers,

            customers_per_page: customers_per_page,

            current_page: page,

            total_pages: total_pages,


            customers: paginated_customers.map do |customer|

              user = customer[:user]


              {
                id: user.id,
                email: user.email,

                created_at: user.created_at,
                updated_at: user.updated_at,

                role: user.role,

                first_name: user.first_name,
                last_name: user.last_name,

                phone_number: user.phone_number,

                terms_accepted: user.terms_accepted,
                terms_accepted_at: user.terms_accepted_at,

                marketing_consent: user.marketing_consent,


                total_bookings: customer[:total_bookings],

                total_spent: customer[:total_spent].to_i,

                active: customer[:active],


                first_booking: customer[:first_booking],

                last_booking: customer[:last_booking]
              }

            end

          }, status: :ok

        end

        def get_customer
          business = ::Business.find_by(id: params[:id])
          user = ::User.find(params[:customer_id])

          unless user.role == 'customer'
            return render json: {
              error: "User is not a Customer."
            }, status: :not_found
          end

          render json: {
            user: {
              id: user.id,
              email: user.email,
              created_at: user.created_at,
              updated_at: user.updated_at,
              role: user.role,
              first_name: user.first_name,
              last_name: user.last_name,
              phone_number: user.phone_number,
              terms_accepted: user.terms_accepted,
              terms_accepted_at: user.terms_accepted_at,
              marketing_consent: user.marketing_consent
            }
          }, status: :ok

          byebug
        end

      end
    end
  end
end
