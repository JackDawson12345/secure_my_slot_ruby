class BusinessSitesController < ApplicationController

  before_action :set_business
  before_action :check_products, only: [:shop, :product, :cart, :checkout]
  helper_method :cart_count

  layout "business_site"

  def show
    track_page_view(@business)

    @coordinates = geocode_business_address


    settings = @business.business_setting
    check_verify_link = settings.check_verify_link

    if check_verify_link.present?
      check_verify_slug = URI.parse(check_verify_link).path.split("/").last

      uri = URI("https://www.checkverify.co.uk/api/v1/reviews/user/#{check_verify_slug}")

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        recent_reviews = data["reviews"]
                           .sort_by { |review| Time.parse(review["created_at"]) }
                           .reverse
                           .first(10)

        @total_reviews =  data.dig("user", "total_reviews")
        @average_rating = data.dig("user", "average_rating").to_f.round(2)
        @reviews = recent_reviews
      end
    end

  end

  def check_service_coupon

    coupon = @business.service_coupons.find do |service_coupon|
      service_coupon.code.strip.casecmp(params[:code].strip).zero?
    end

    unless coupon
      render json: {
        success: false,
        message: "Coupon code not found."
      }
      return
    end


    unless coupon.active?
      render json: {
        success: false,
        message: "This coupon is no longer active."
      }
      return
    end


    if coupon.expires_at.present? && coupon.expires_at < Time.current
      render json: {
        success: false,
        message: "This coupon has expired."
      }
      return
    end


    service_id = params[:service_id].to_s


    if coupon.services.present?

      allowed_services =
        coupon.services.map(&:to_s)

      unless allowed_services.include?(service_id)
        render json: {
          success: false,
          message: "This coupon cannot be used for this service."
        }
        return
      end

    end


    service = @business.services.find(service_id)


    original_price = service.price.to_d


    discounted_price =
      case coupon.coupon_type

      when "percentage"
        original_price -
          (original_price * (coupon.discount / 100))

      when "fixed"
        original_price - coupon.discount

      else
        original_price
      end


    discounted_price = 0 if discounted_price < 0


    render json: {
      success: true,
      message: "Coupon applied successfully.",
      original_price: original_price.to_f,
      price: discounted_price.round(2).to_f
    }

  end

  def consultation_form
    @consultation_form = @business.consultation_form

    unless params[:token].present?
      redirect_to root_url(
                    subdomain: @business.page_address
                  )
      return
    end

    @booking = @business.bookings.find_by(
      consultation_token: params[:token]
    )

    unless @booking
      redirect_to root_url(
                    subdomain: @business.page_address
                  )
      return
    end
  end

  def submit_consultation_form
    @consultation_form = @business.consultation_form

    @booking = @business.bookings.find_by(
      consultation_token: params[:token]
    )

    unless @booking
      redirect_to root_url(
                    subdomain: @business.page_address
                  )
      return
    end

    submitted_answers =
      params[:consultation]&.to_unsafe_h || {}

    responses = build_consultation_responses(
      @consultation_form.structure,
      submitted_answers
    )

    @booking.update!(
      consultation_responses: responses
    )

    redirect_to root_url(
                  subdomain: @business.page_address
                ),
                notice: "Consultation form submitted successfully."
  end

  def agreement_form
    @agreement_status = AgreementStatus.find_by(token: params[:token])

    return redirect_to root_path unless @agreement_status

    @agreement = @agreement_status.agreement
  end

  def submit_agreement_form

    @agreement_status = AgreementStatus.find_by(token: params[:token])

    if params[:signature_data].present?

      params[:signature_data].each do |name, signature|

        next if signature.blank?

        image_data = signature.split(",").last

        @agreement_status.signatures.attach(
          io: StringIO.new(Base64.decode64(image_data)),
          filename: "#{name}.png",
          content_type: "image/png"
        )

      end

    end


    browser = Browser.new(request.user_agent)

    @agreement_status.update!(
      status: "signed",
      signed_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      device: "#{browser.device.name} - #{browser.name} #{browser.version}"
    )


    redirect_to business_site_agreement_form_path(token: @agreement_status.token),
                notice: "Agreement signed successfully."

  end

  def shop
    @products = @business.products
  end

  def product
    @product = @business.products.find_by(slug: params[:slug])
  end

  def cart

    @cart_items = cart_products


    @subtotal = @cart_items.sum do |item|

      product = item[:product]


      price =
        if product.sale_price.present?
          product.sale_price
        else
          product.regular_price
        end


      price * item[:quantity]

    end

  end

  def checkout

    @cart_items = cart_products


    @subtotal = @cart_items.sum do |item|

      price =
        item[:product].sale_price.presence ||
        item[:product].regular_price


      price * item[:quantity]

    end

  end

  def add_to_cart

    product = @business.products.find(params[:product_id])


    cart = current_cart


    product_id = product.id.to_s

    quantity = params[:quantity].to_i

    quantity = 1 if quantity < 1


    cart[product_id] =
      cart.fetch(product_id, 0) + quantity


    save_cart(cart)


    redirect_to business_site_cart_path

  end

  def update_cart

    cart = current_cart


    params[:quantities].each do |product_id, quantity|

      quantity = quantity.to_i


      if quantity <= 0
        cart.delete(product_id)
      else
        cart[product_id] = quantity
      end

    end


    save_cart(cart)


    redirect_to business_site_cart_path

  end

  def remove_from_cart

    cart = current_cart


    cart.delete(params[:id].to_s)


    save_cart(cart)


    redirect_to business_site_cart_path

  end

  def create_order

    user = find_or_create_checkout_user


    if params[:payment_method] == "stripe"

      create_stripe_order_hold(
        user: user
      )

    else

      create_cash_order(
        user: user
      )

    end

  end

  def payment_success

    hold = OrderHold.find(params[:id])


    if hold.order.present?
      redirect_to order_confirmation_path(
                    public_id: hold.order.public_id
                  )
      return
    end


    unless params[:session_id].present?

      redirect_to business_site_cart_path,
                  alert: "Payment session missing."

      return

    end


    unless valid_order_payment_session?(hold)

      redirect_to business_site_cart_path,
                  alert: "Payment could not be verified."

      return

    end


    stripe_session =
      Stripe::Checkout::Session.retrieve(
        params[:session_id],
        {
          stripe_account:
            hold.business.stripe_account_id
        }
      )


    unless stripe_session.payment_status == "paid"

      redirect_to business_site_cart_path,
                  alert: "Payment was not completed."

      return

    end



    order = Order.create!(
      business: hold.business,
      user: hold.user,
      status: "pending",
      payment_method: "stripe",
      payment_status: "paid",
      stripe_checkout_session_id: stripe_session.id,
      stripe_payment_intent_id: stripe_session.payment_intent,
      amount: hold.amount,
      address_line_1: hold.address_line_1,
      address_line_2: hold.address_line_2,
      town: hold.town,
      postcode: hold.postcode
    )


    create_order_items_from_hold(
      order,
      hold
    )


    hold.update!(
      order: order
    )


    clear_cart


    redirect_to order_confirmation_path(
                  public_id: order.public_id
                )

  end

  def order_confirmation

    @order =
      @business.orders.find_by!(
        public_id: params[:public_id]
      )

  end

  private

  def find_or_create_checkout_user

    email = params[:email].to_s.downcase.strip

    user = User.find_or_initialize_by(
      email: email
    )


    user.assign_attributes(
      first_name: params[:first_name],
      last_name: params[:last_name],
      phone_number: params[:phone_number],
      role: :customer
    )


    if user.new_record?

      user.password =
        generate_customer_password

      user.terms_accepted = true

    end


    user.save!


    user.create_customer_setting! unless user.customer_setting


    user

  end

  def generate_customer_password
    [
      ("A".."Z").to_a.sample,
      ("0".."9").to_a.sample,
      ["!", "@", "#", "$", "%"].sample,
      SecureRandom.hex(8)
    ].join
  end

  def create_cash_order(user:)

    order = Order.create!(
      business: @business,
      user: user,
      status: "pending",
      payment_method: "cash",
      payment_status: "unpaid",
      amount: checkout_total,
      address_line_1: params[:address_line_1],
      address_line_2: params[:address_line_2],
      town: params[:town],
      postcode: params[:postcode],
    )


    create_order_items(order)


    clear_cart


    redirect_to order_confirmation_path(
                  public_id: order.public_id
                )

  end

  def create_order_items(order)

    cart_products.each do |item|

      product = item[:product]


      price =
        product.sale_price.presence ||
        product.regular_price


      order.order_items.create!(
        product: product,
        quantity: item[:quantity],
        price: price
      )

    end

  end

  def create_stripe_order_hold(user:)

    hold = OrderHold.create!(
      business: @business,
      user: user,
      amount: checkout_total,
      expires_at: 30.minutes.from_now,
      cart_data: current_cart.deep_dup,
      address_line_1: params[:address_line_1],
      address_line_2: params[:address_line_2],
      town: params[:town],
      postcode: params[:postcode]
    )


    session = Stripe::Checkout::Session.create(

      {
        mode: "payment",

        customer_email: user.email,

        line_items: stripe_line_items,

        metadata: {
          order_hold_id: hold.id
        },

        success_url:
          "#{order_payment_success_url(hold, subdomain: @business.page_address)}?session_id={CHECKOUT_SESSION_ID}",

        cancel_url:
          business_site_cart_url

      },

      {
        stripe_account:
          @business.stripe_account_id
      }

    )


    hold.update!(
      stripe_checkout_session_id: session.id
    )


    redirect_to session.url,
                allow_other_host: true

  end

  def stripe_line_items

    cart_products.map do |item|

      product = item[:product]

      price =
        product.sale_price.presence ||
        product.regular_price


      {
        quantity: item[:quantity],

        price_data: {

          currency: "gbp",

          unit_amount:
            price_in_pence(price),

          product_data: {
            name: product.name,
            images: stripe_product_images(product)
          }

        }

      }

    end

  end

  def stripe_product_images(product)

    return [] unless product.featured_image.attached?

    [
      url_for(product.featured_image)
    ]

  end

  def checkout_total

    cart_products.sum do |item|

      product = item[:product]

      price =
        product.sale_price.presence ||
        product.regular_price


      price * item[:quantity]

    end

  end

  def set_business
    @business = Business.find_by(page_address: request.subdomain)

    render file: Rails.root.join("public/404.html"),
           status: :not_found unless @business
  end

  def check_products
    unless @business.products.exists?
      redirect_to business_site_path
    end
  end

  def consultation_form_params
    params.require(:consultation_form).permit(:structure)
  end

  def geocode_business_address
    address = [
      @business.business_setting.address_line_1,
      @business.business_setting.address_line_2,
      @business.business_setting.town_or_city,
      @business.business_setting.postcode,
      @business.business_setting.country
    ].compact.join(", ")

    response = HTTParty.get(
      "https://maps.googleapis.com/maps/api/geocode/json",
      query: {
        address: address,
        key: ENV["GOOGLE_MAPS_API_KEY"].presence ||
          Rails.application.credentials.dig(:google_maps, :api_key)
      }
    )

    result = response.parsed_response["results"].first

    return nil unless result

    {
      latitude: result["geometry"]["location"]["lat"],
      longitude: result["geometry"]["location"]["lng"]
    }
  end

  def build_consultation_responses(structure, submitted_answers)
    structure =
      if structure.is_a?(String)
        JSON.parse(structure) rescue []
      else
        structure || []
      end

    responses = []

    structure.each do |row|
      next unless row["type"] == "row"

      (row["children"] || []).each do |column|
        next unless column["type"] == "column"

        (column["children"] || []).each do |field|
          next unless %w[text number textarea select].include?(field["type"])

          field_name = field["name"]

          next if field_name.blank?
          next unless submitted_answers.key?(field_name)

          responses << {
            "id" => field["id"],
            "label" => field["placeholder"].presence || field_name.humanize,
            "value" => submitted_answers[field_name]
          }
        end
      end
    end

    responses
  end

  def current_cart

    session[:carts] ||= {}


    session[:carts][@business.id.to_s] ||= {}

  end

  def save_cart(cart)

    session[:carts] ||= {}


    session[:carts][@business.id.to_s] = cart

  end

  def cart_products

    products =
      @business.products.where(
        id: current_cart.keys
      )


    products.map do |product|

      {
        product: product,
        quantity: current_cart[product.id.to_s]
      }

    end

  end

  def cart_count

    current_cart.values.sum

  end

  def clear_cart

    session[:carts][@business.id.to_s] = {}

  end

  def valid_order_payment_session?(hold)

    return false if hold.stripe_checkout_session_id.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      params[:session_id].to_s,
      hold.stripe_checkout_session_id
    )

  end

  def create_order_items_from_hold(order, hold)

    hold.cart_data.each do |product_id, quantity|

      product =
        hold.business.products.find(product_id)


      price =
        product.sale_price.presence ||
        product.regular_price


      order.order_items.create!(
        product: product,
        quantity: quantity,
        price: price
      )

    end

  end

  def price_in_pence(price)
    (BigDecimal(price.to_s) * 100).round.to_i
  end

end