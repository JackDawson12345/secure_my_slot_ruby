class Users::PasswordsController < Devise::PasswordsController
  protected

  def after_resetting_password_path_for(resource)
    activate_agent(resource)

    super
  end

  private

  def activate_agent(user)
    return unless user.agent?

    user.business_agents
        .where(status: :invited)
        .update_all(
          status: BusinessAgent.statuses[:active],
          updated_at: Time.current
        )
  end
end