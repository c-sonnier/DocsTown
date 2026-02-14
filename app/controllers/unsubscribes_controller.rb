class UnsubscribesController < ApplicationController
  # RFC 8058 one-click unsubscribe: mail clients POST without a session/CSRF token
  skip_before_action :verify_authenticity_token, only: :create

  def show
    @user = find_user_from_token
    if @user
      render :show
    else
      redirect_to root_path, alert: "Invalid or expired unsubscribe link."
    end
  end

  def create
    user = find_user_from_token
    if user
      user.update!(digest_opted_in: false)
      redirect_to unsubscribe_path(token: params[:token]), notice: "You have been unsubscribed."
    else
      redirect_to root_path, alert: "Invalid or expired unsubscribe link."
    end
  end

  private

  def find_user_from_token
    user_id = User.unsubscribe_verifier.verify(params[:token], purpose: :unsubscribe)
    User.find_by(id: user_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
