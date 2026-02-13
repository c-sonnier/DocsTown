class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_initialize_by(github_uid: auth.uid)
    user.update!(
      github_username: auth.info.nickname,
      avatar_url: auth.info.image,
      email: auth.info.email
    )

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
    redirect_to root_path, alert: "Authentication failed: #{params[:message].to_s.humanize}"
  end
end
