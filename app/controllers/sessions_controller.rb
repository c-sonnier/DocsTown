class SessionsController < ApplicationController
  FAILURE_MESSAGES = {
    "csrf_detected" => "Request verification failed. Please try again.",
    "invalid_credentials" => "Authentication failed."
  }.freeze

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_initialize_by(github_uid: auth.uid)
    user.update!(
      github_username: auth.info.nickname,
      avatar_url: auth.info.image,
      email: auth.info.email
    )

    reset_session
    session[:user_id] = user.id
    Current.user = user

    redirect_to root_path, notice: "Signed in as #{user.github_username}"
  end

  def destroy
    reset_session
    Current.user = nil

    redirect_to root_path, notice: "Signed out"
  end

  def failure
    msg = FAILURE_MESSAGES[params[:message].to_s] || "Authentication failed. Please try again."
    redirect_to root_path, alert: msg
  end
end
