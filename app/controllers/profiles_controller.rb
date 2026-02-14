class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = Current.user
  end

  def update
    @user = Current.user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Settings saved successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:email, :digest_opted_in)
  end
end
