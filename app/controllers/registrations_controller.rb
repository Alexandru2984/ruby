class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 5, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }
  before_action :ensure_signups_enabled
  before_action :redirect_if_authenticated

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.expect(user: [ :email_address, :password, :password_confirmation ])
    end

    def redirect_if_authenticated
      redirect_to root_path if authenticated?
    end

    def ensure_signups_enabled
      redirect_to new_session_path, alert: "Sign-ups are disabled on this server." unless signups_enabled?
    end
end
