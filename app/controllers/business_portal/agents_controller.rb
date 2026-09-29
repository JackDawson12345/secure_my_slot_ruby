class BusinessPortal::AgentsController < BusinessPortal::BaseController
  before_action :set_business
  before_action :set_business_agent, only: %i[edit update destroy resend_invitation]

  def index
    @business_agents = @business
                         .business_agents
                         .includes(:user)
                         .order(created_at: :desc)
  end

  def new
    @agent = User.new
  end

  def create
    @agent = User.find_by(email: agent_params[:email])

    if @agent
      add_existing_agent
    else
      create_new_agent
    end
  end

  def edit
    @agent = @business_agent.user
  end

  def update
    @agent = @business_agent.user

    if @agent.update(agent_params.except(:email))
      redirect_to business_agents_path,
                  notice: "Agent updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @business_agent.destroy!

    redirect_to business_agents_path,
                notice: "Agent removed successfully."
  end

  def resend_invitation
    @agent = @business_agent.user

    send_agent_invitation(@agent)

    @business_agent.update!(
      invited_at: Time.current
    )

    redirect_to business_agents_path,
                notice: "Invitation resent successfully."
  end

  private

  def set_business
    @business = current_user.business
  end

  def set_business_agent
    @business_agent = @business.business_agents.find(params[:id])
  end

  def agent_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :phone_number
    )
  end

  def create_new_agent
    @agent = User.new(agent_params)

    @agent.role = :agent
    @agent.invitation_creation = true

    @agent.password = SecureRandom.hex(32)

    User.transaction do
      @agent.save!

      @business_agent = @business.business_agents.create!(
        user: @agent,
        status: :invited,
        invited_at: Time.current
      )
    end

    send_agent_invitation(@agent)

    redirect_to business_agents_path,
                notice: "Agent invitation sent successfully."

  rescue ActiveRecord::RecordInvalid => e
    @agent.errors.add(
      :base,
      e.record.errors.full_messages.to_sentence
    ) unless e.record == @agent

    render :new, status: :unprocessable_entity
  end

  def add_existing_agent
    if @business.business_agents.exists?(user: @agent)
      @agent.errors.add(
        :email,
        "is already associated with this business"
      )

      render :new, status: :unprocessable_entity
      return
    end

    @business.business_agents.create!(
      user: @agent,
      status: :active
    )

    redirect_to business_agents_path,
                notice: "Agent added successfully."
  end

  def send_agent_invitation(agent)
    raw_token, encrypted_token = Devise.token_generator.generate(
      User,
      :reset_password_token
    )

    agent.update_columns(
      reset_password_token: encrypted_token,
      reset_password_sent_at: Time.current
    )

    AgentMailer
      .invitation(agent, @business, raw_token)
      .deliver_later
  end
end